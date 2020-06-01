#!/usr/bin/env python3

import os.path
import cv2
from numpy import array, uint8, ones, append
from math import atan2, pi, degrees, sqrt
import infieldFittingRoutines

import time

# This data represents initial user input to tell which corner of the infield represents home plate
HOME_PLATE_ANGLES = [       #in degrees
    176.740300712375,       #image1.jpg
    -157.19834043383372,    #image2.jpg
    -145.90439732553747,    #image3.jpg
    -139.65636091098264,    #...
    -116.89130389332098,
    -100.62383203858792,
    -178.07661082248038,
    10.105372086090268,
    -129.54996512403113,
    8.259332720696968,
    None,
    8.0
]


class PlayerFinder(object):
    def __init__(self):
        self.lower_green = array((17, 50, 20), dtype=uint8)
        self.upper_green = array((72, 255, 242), dtype=uint8)

        self.lower_brown = array((7, 80, 25), dtype=uint8)
        self.upper_brown = array((27, 255, 255), dtype=uint8)

        self.lower_dark_brown = array((2, 93, 25), dtype=uint8)
        self.upper_dark_brown = array((10, 175, 150), dtype=uint8)

        self.player_contours = None
        self.top_players = None
        self.players = None

        self.infield_contours = None
        self.top_infield = None
        self.infield = None
        self.infield_cnrs = None

        self.positions = []         # order: (pitcher, home, first, second, third, shortstop, left field, center field, right field)
        self.expectedPositions = [] # same order

        return

    def reset_variables(self):
        self.player_contours = None
        self.top_players = None
        self.players = None

        self.infield_contours = None
        self.top_infield = None
        self.infield = None
        self.infield_cnrs = None

        self.positions = []
        self.expectedPositions = []

    def process_image(self, image, angle):
        '''Main image processing routine
        
        1. Reset all central class variables to make sure the last image's processing data is cleared out
        2. Convert color from BGR to HSV
        3. Find all the pixels in the image that are a specific shade of green or brown to identify the field and dirt
        4. Find the location of the bases
        5. Find the location of the players
        6. Calculate the ideal location of each of the players' positions
        7. Assign each player an expected position
        8. RETURN each players' bottom point and their corresponding position
        '''
        
        self.reset_variables()

        #converting into hsv image
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

        #Define a mask ranging from lower to uppper
        mask_green = cv2.inRange(hsv, self.lower_green, self.upper_green)
        mask_brown = cv2.inRange(hsv, self.lower_brown, self.upper_brown)
        mask_dark_brown = cv2.inRange(hsv, self.lower_dark_brown, self.upper_dark_brown)

        mask = cv2.bitwise_or(mask_green, mask_brown)
        mask = cv2.bitwise_or(mask, mask_dark_brown)
        
        im = self.get_players_position_locations(mask_green, image, angle)    #pass in image for quad fit debugging
        if im is None:
            return image
        image = im      #updates output for drawing debug of quad_fit
        
        self.get_player_contours(mask)
        
        returnDictionary = self.get_player_dictionary()
        print(returnDictionary)
 
        return image
    
    def get_players_position_locations(self, mask, image, expected_home_plate_angle):
        '''Sub-processing routine to find the location of each of the game positions

        1. Erode the image to get rid of small impurities
        2. Find all contours that are formed by the green mask
        3. Choose the contours that are between a certain bounding box area
        4. Choose the contours that have a certain (height/width) ratio, the smallest bounding box width, and an exact area above a certain threshold
                --> the expected infield outline
        5. Fit a quadrilateral around the infield grass
        6. Compute ideal position locations based on the infield corners
        7. RETURN the image locations corresponding the positions in the following order:
                (pitcher, catcher, first, second, third, shortstop, left field, center field, right field)
        '''

        erosion = cv2.erode(mask, ones((4, 4), uint8), iterations = 1)
        _, self.infield_contours, _ = cv2.findContours(erosion, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        infield_contour_list = self.area_cut(self.infield_contours, 18500, 2000000)
        #self.infield = min(infield_contour_list, key=lambda x:x['area'])['contour']
        
        self.top_infield = [x['contour'] for x in infield_contour_list]

        for cnt in infield_contour_list:
            width = cnt['widths'][0]
            height = cnt['widths'][1]
            ratio = height / width

            if (ratio < 0.4) and (self.infield is None or width < self.infield['widths'][0]) and cv2.contourArea(cnt['contour']) > 10000:
                self.infield = cnt

        if self.infield is None:
            return None
        
        infieldShape = self.infield['widths']
        self.infield = cv2.convexHull(self.infield['contour'])

        # to find quadrilateral using hough_fit method
        cnrs = self.quad_fit(self.infield, image_frame=image)   # returns corner array in counterclockwise order

        if cnrs is None:
            return None

        pitcher_mound_x = (cnrs[0][0] + cnrs[1][0] + cnrs[2][0] + cnrs[3][0]) / 4
        pitcher_mound_y = (cnrs[0][1] + cnrs[1][1] + cnrs[2][1] + cnrs[3][1]) / 4

        da = 361    #delta angle
        home_plate_index = None

        if expected_home_plate_angle is None:       #TODO: this should be move up to first in processing
            return None

        for i in range(0, len(cnrs)):
            x = cnrs[i][0] - pitcher_mound_x
            y = pitcher_mound_y - cnrs[i][1]        #flip because y goes up as the pixel location goes down
            angle = atan2(y, x) * (180 / pi)    #change to degrees -- more readable format for debugging
            
            da_temp = abs(angle - expected_home_plate_angle)   #TODO use the device's gyroscope to adjust the expected angle based on the device's rotation

            if da_temp < da:
                da = da_temp
                home_plate_index = i

        if home_plate_index is None:
            return None
        
        self.infield_cnrs = cnrs.astype(int)

        homePlate = self.infield_cnrs[home_plate_index]
        secondBase = self.infield_cnrs[(home_plate_index + 2) % 4]  #can do this since the corners are in order, either clockwise or counter-clockwise

        #Find which is first base and which is third base:
        testBaseIndex = (home_plate_index + 1) % 4
        x = self.infield_cnrs[testBaseIndex][0] - pitcher_mound_x
        y = pitcher_mound_y - cnrs[testBaseIndex][1]
        angle = atan2(y, x) * (180 / pi)

        if angle < 0:
            angle += 360
        if expected_home_plate_angle < 0:
            expected_home_plate_angle += 360
        
        # first base must be the next base if moving in a counter-clockwise direction in relation to the pitcher's mound
        if (angle > expected_home_plate_angle and angle < expected_home_plate_angle + 180)  or (angle + 360 > expected_home_plate_angle and angle + 360 < expected_home_plate_angle + 180):
            firstBase = self.infield_cnrs[(home_plate_index + 1) % 4]
            thirdBase = self.infield_cnrs[(home_plate_index + 3) % 4]
        else:
            firstBase = self.infield_cnrs[(home_plate_index + 3) % 4]
            thirdBase = self.infield_cnrs[(home_plate_index + 1) % 4]

        self.expectedPositions.append([int(pitcher_mound_x), int(pitcher_mound_y)])
        calculatedPositions = self.calculateExpectedPositions(homePlate, firstBase, secondBase, thirdBase, infieldShape)

        # To draw the corners of the infield grass:
        """self.positions.append(homePlate)
        self.positions.append(firstBase)
        self.positions.append(secondBase)
        self.positions.append(thirdBase)"""

        for pos in calculatedPositions:
            self.expectedPositions.append(pos)

        return image
    
    def calculateExpectedPositions(self, homePlate, firstBase, secondBase, thirdBase, infieldShape):
        '''Helper method to calculate the expected location of each player position in the image
        provided the base coordinates'''

        homeToFirstDist = self.getDistBetweenPoints(homePlate, firstBase)
        firstToSecondDist = self.getDistBetweenPoints(firstBase, secondBase)
        secondToThirdDist = self.getDistBetweenPoints(secondBase, thirdBase)
        thirdToHomeDist = self.getDistBetweenPoints(thirdBase, homePlate)
        # TODO: could potentially do more with this since we know each of these in real life should be around 90 ft

        side1 = (homeToFirstDist + secondToThirdDist) / 2   #average the two sides of the infield out to get a more consistent elevation multiplier
        side2 = (firstToSecondDist + thirdToHomeDist) / 2   #represents side1 and side2 of a parallelogram fitted around the infield grass
        
        distRatio = side1 / side2
        #print(distRatio)

        def addBaseID(arr, val):
            newArr = arr.tolist()
            newArr.append(val)
            return newArr

        sortedBases = [addBaseID(homePlate, 0.0), addBaseID(firstBase, 1.0), addBaseID(secondBase, 2.0), addBaseID(thirdBase, 3.0)]
        sortedBases.sort(key=lambda b: b[1], reverse=True)
        
        # TODO: when able to get a real image test set, revise these values and maybe model them with some sort of function if possible

        if sortedBases[0][2] == 2.0 or (sortedBases[0][2] == 1.0 and sortedBases[1][2] == 2.0) or (sortedBases[0][2] == 3.0 and sortedBases[1][2] == 2.0):    #If the user is closer towards the outfield than the infield...
            #print("outfield")
            #use vector operations to calculate expected positions from the coordinates of the bases and the elevation multipliers
            if distRatio >= 4.0:        # first to second is smaller, so refine right infield, leftfield, and centerfield (same amount at if <= 0.25)
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)
            elif distRatio <= 0.25:     # home to first is smaller, so refine left infield, rightfield, and centerfield (same as if >= 4.0)
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)
            else:                       # normal
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)
            #print(leftfield)
        else:       #if the user is closer to the infield...
            #print("infield")
            if distRatio >= 4.0:        # first to second is smaller, so refine right infield, leftfield, and centerfield (same amount at if <= 0.25)
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.7, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)
            elif distRatio <= 0.25:     # home to first is smaller, so refine left infield, rightfield, and centerfield (same as if >= 4.0)
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.7, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)
            else:                       # normal
                first = self.calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25)
                second = self.calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25)
                shortstop = self.calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2)
                third = self.calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2)
                leftfield = self.calculatePosition(homePlate, secondBase, thirdBase, 0.7, 1.7)
                centerfield = (homePlate + (1.5 * (secondBase - homePlate))).astype(int)
                rightfield = self.calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7)

        return [homePlate, first, second, shortstop, third, leftfield, centerfield, rightfield]

    def calculatePosition(self, homePlate, base1, base2, betweenBaseMultiplier, distanceToHomeMultiplier):
        '''Calculate the expected postition of a player a certain percent of the way between two bases and
        a certain percent of the way from home using vector operations'''

        return (homePlate + ((base1 + (betweenBaseMultiplier * (base2 - base1))) - homePlate ) * distanceToHomeMultiplier).astype(int)
    
    def get_player_contours(self, mask):
        '''Sub-processing routine to find the location of the players on the field

        1. Erode the image to get rid of small impurities
        2. Find all contours that are formed by the green and brown masks
        3. Choose the contours that are between a certain bounding box area
        4. Choose the contours that have a certain (height/width) ratio and actually are located on the field
        5. RETURN an array of the players' center pixel location
        '''

        erosion = cv2.erode(mask, ones((5,5), uint8), iterations = 1)   
        _, self.player_contours, _ = cv2.findContours(erosion, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        
        field = None

        contour_list = []
        for c in self.player_contours:
            center, widths = self.contour_center_width(c)
            area = widths[0] * widths[1]

            if area > 270 and area < 2000:
                contour_list.append({'contour': c, 'center': center, 'widths': widths, 'area': area})

            if field is None or field['area'] < area:
                field = {'contour': c, 'center': center, 'widths': widths, 'area': area}
            
        # Sort the list of contours from biggest area to smallest
        contour_list.sort(key=lambda c: c['widths'][0] * c['widths'][1], reverse=True)
        
        self.top_players = []

        for player in contour_list:
            width = player['widths'][0]
            height = player['widths'][1]
            ratio = height / width

            if ratio >= 0.8 and ratio <= 3.0:
                self.top_players.append(player)

        if len(self.top_players) == 0:
            self.top_players = None
            return

        self.players = []

        for candidate in self.top_players:
            if self.isCandidatePlayerOnField(candidate['center'], field):
                self.players.append(candidate['contour'])
        
        self.top_players = [x['contour'] for x in self.top_players]

    def isCandidatePlayerOnField(self, candidateCenterPt, fieldInfo):
        '''Helper method to check is a candidate player is located on the field

        1. Check if the candidate player's center point is within the field's bounding box 
            (much faster than the opencv method, so if it isn't in the bounding box it's a quick reliable way to return false)
        2. Check if the center point is actually inside the field contour
        3. RETURN true if the result is positive
        '''

        width = int( fieldInfo['widths'][0] / 2 )
        height = int( fieldInfo['widths'][1] / 2 )
        centerx = fieldInfo['center'][0]
        centery = fieldInfo['center'][1]
        
        #if center of candidate player is not even in the field's bounding box, definitely is not inside the contour
        if candidateCenterPt[0] >= centerx + width or candidateCenterPt[0] <= centerx - width or candidateCenterPt[1] <= centery - height and candidateCenterPt[1] >= centery + height:
            return False
        
        distance = cv2.pointPolygonTest(fieldInfo['contour'], candidateCenterPt, True)
        
        if distance <= 0:   #outside of contour or on edge of contour
            return False
        
        return True

    def area_cut(self, cnts, min_area, max_area):
        '''Helper method for a generic contour area cut according to its bounding box'''

        contour_list = []
        for c in cnts:
            center, widths = self.contour_center_width(c)
            area = widths[0] * widths[1]

            if area > min_area and area < max_area:
                contour_list.append({'contour': c, 'center': center, 'widths': widths, 'area': area})
            
        # Sort the list of contours from biggest area to smallest
        contour_list.sort(key=lambda c: c['widths'][0] * c['widths'][1], reverse=True)

        return contour_list

    def contour_center_width(self, contour):
        '''Find boundingRect of contour, but return center and width/height'''

        x, y, w, h = cv2.boundingRect(contour)
        return (x + int(w / 2), y + int(h / 2)), (w, h)

    def quad_fit(self, contour, image_frame=None):
        '''Best fit of a quadrilateral to the contour'''

        #approx = infieldFittingRoutines.approxPolyDP_adaptive(contour, nsides=4)
        return infieldFittingRoutines.hough_fit(contour, nsides=4, approx_fit=None, image_frame=None)

    def get_player_dictionary(self):
        playersByPosition = {"pitcher": [],
                                "catcher": [],
                                "first": [],
                                "second": [],
                                "shortstop": [],
                                "third": [],
                                "leftfield": [],
                                "centerfield": [],
                                "rightfield": [],
                                "offense": self.infield_cnrs}   # TODO make the dictionary keys into what names the website calls each
                                                                #      position so the names can be used to directly look up each players
                                                                #      position

        for player in self.players:
            lowestPt = max(player, key=lambda x: x[0][1])[0]
            closestPosition = []    #saves index of and distance to closest expected position
            
            for i in range(9):  #there are 9 expected positions
                dist = self.getDistBetweenPoints(lowestPt, self.expectedPositions[i])

                if closestPosition == [] or dist < closestPosition[1]:
                    closestPosition = [i, dist]
            
            if closestPosition[0] == 0:
                playersByPosition["pitcher"].append(lowestPt)
            elif closestPosition[0] == 1:
                playersByPosition["catcher"].append(lowestPt)
            elif closestPosition[0] == 2:
                playersByPosition["first"].append(lowestPt)
            elif closestPosition[0] == 3:
                playersByPosition["second"].append(lowestPt)
            elif closestPosition[0] == 4:
                playersByPosition["shortstop"].append(lowestPt)
            elif closestPosition[0] == 5:
                playersByPosition["third"].append(lowestPt)
            elif closestPosition[0] == 6:
                playersByPosition["leftfield"].append(lowestPt)
            elif closestPosition[0] == 7:
                playersByPosition["centerfield"].append(lowestPt)
            else: # == 8
                playersByPosition["rightfield"].append(lowestPt)
            
        return playersByPosition


    def getDistBetweenPoints(self, pt1, pt2):
        return sqrt( ((pt1[0] - pt2[0]) ** 2) + ((pt1[1] - pt2[1]) ** 2) )


    def prepare_output_image(self, input_frame):
        '''Prepare output image for drive station. Draw the found target contour.'''

        output_frame = input_frame.copy()

        # Draw the contours on the image

        """
        #blue
        if self.player_contours is not None:
            cv2.drawContours(output_frame, self.player_contours, -1, (255, 0, 0), 1)
        
        #green
        if self.top_players is not None:
            cv2.drawContours(output_frame, self.top_players, -1, (0, 255, 0), 2)
        """
        #red
        if self.players is not None:
            cv2.drawContours(output_frame, self.players, -1, (0, 0, 255), 3)
        """
        #blue
        if self.infield_contours is not None:
            cv2.drawContours(output_frame, self.infield_contours, -1, (255, 0, 0), 1)

        #green
        if self.top_infield is not None:
            cv2.drawContours(output_frame, self.top_infield, -1, (0, 255, 0), 2)
        
        #green
        if self.infield is not None:
            cv2.drawContours(output_frame, [self.infield], -1, (0, 255, 0), 3)
        
        #yellow
        if self.infield_cnrs is not None:
            for cnr in self.infield_cnrs:
                cv2.drawMarker(output_frame, tuple(cnr), (0, 255, 255), cv2.MARKER_CROSS, 20, 5)
        """

        #Shades of blue
        if self.expectedPositions is not None and len(self.expectedPositions) != 0:
            b = 0
            add = int(255 / len(self.expectedPositions))
            for pos in self.expectedPositions:
                cv2.drawMarker(output_frame, tuple(pos), (b, 0, 0), cv2.MARKER_CROSS, 20, 5)
                b+=add
        
        """if self.expectedPositions is not None and len(self.expectedPositions) != 0:
            for pos in self.expectedPositions:
                cv2.drawMarker(output_frame, tuple(pos), (0, 255, 0), cv2.MARKER_CROSS, 20, 5)"""

        return output_frame

def process_files(processor, input_files, output_dir):
    '''Process the files and output the marked up image'''
    import os.path

    print()

    for image_file in input_files:
        print("   ** Process image " + str(image_file))
        image_index = ""
        for char in image_file:
            if char.isdigit():
                image_index += char
        
        image_index = int(image_index) - 1  #bc array indices

        bgr_frame = cv2.imread(image_file)

        #-----------------------------resize original image:
        new_height = 1080   # This is the pixel dimensions of the standard iphone 8 camera setting (1080p HD)
        # Makes sure all images are the same height --> same relative player sizes so that contour cuttoffs can be accurate

        scale_percent = new_height / bgr_frame.shape[0]
        width = int(bgr_frame.shape[1] * scale_percent)
        height = int(bgr_frame.shape[0] * scale_percent)
        print("   ** New Image Size: " + str(width) + "x" + str(height))

        resized = cv2.resize(bgr_frame, (width, height), interpolation = cv2.INTER_AREA)
        #--------------------------------------------

        t0 = time.time()
        
        testing_output = processor.process_image(resized, HOME_PLATE_ANGLES[image_index])
        markup = processor.prepare_output_image(resized)

        t1 = time.time()
        print("   ** Processing took: " + str(t1-t0) + " sec\n")

        outfile = os.path.join(output_dir, os.path.basename(image_file))

        cv2.imwrite(outfile, markup)

    return

def main():
    '''Main routine'''
    import argparse

    parser = argparse.ArgumentParser(description='MLB_AR Person Detection Testing')
    parser.add_argument('--output_dir', help='Output directory for processed images')
    parser.add_argument('input_files', nargs='+', help='input files')

    args = parser.parse_args()

    processor = PlayerFinder()

    if args.output_dir is not None:
        process_files(processor, args.input_files, args.output_dir)
    else:
        print("Please specify an output directory for the marked up images")

    return

if __name__ == "__main__":
    main()