#!/usr/bin/env python3

import os.path
import cv2
from numpy import array, uint8, ones, append
from math import atan2, pi
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
    None
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

        self.positions = []  #order: (pitcher, home, first, second, third, shortstop, left field, center field, right field)

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
        if im is not None:
            image = im      #updates output for drawing debug of quad_fit
        self.get_player_contours(mask)
 
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
                (pitcher, home, first, second, third, shortstop, left field, center field, right field)
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
        
        self.infield = cv2.convexHull(self.infield['contour'])

        # to find quadrilateral using hough_fit method
        cnrs = self.quad_fit(self.infield, image_frame=image)   # returns corner array in counterclockwise order

        if cnrs is None:
            return None

        pitcher_mound_x = (cnrs[0][0] + cnrs[1][0] + cnrs[2][0] + cnrs[3][0]) / 4
        pitcher_mound_y = (cnrs[0][1] + cnrs[1][1] + cnrs[2][1] + cnrs[3][1]) / 4

        da = 361    #delta angle
        home_plate_index = None

        if expected_home_plate_angle is None:
            return None

        for i in range(0, len(cnrs)):
            x = cnrs[i][0] - pitcher_mound_x
            y = pitcher_mound_y - cnrs[i][1]        #flip because y goes up as the pixel location goes down
            angle = atan2(y, x) * (180 / pi)    #change to degrees b/c its a more readable format for debugging
            
            da_temp = abs(angle - expected_home_plate_angle)   #TODO use the device's gyroscope to adjust the expected angle based on the device's rotation

            if da_temp < da:
                da = da_temp
                home_plate_index = i

        if home_plate_index is None:
            return None
        
        self.infield_cnrs = cnrs.astype(int)

        first = (home_plate_index + 1) % 4
        second = (home_plate_index + 2) % 4
        third = (home_plate_index + 3) % 4

        self.positions.append([int(pitcher_mound_x), int(pitcher_mound_y)])
        self.positions.append(self.infield_cnrs[home_plate_index])
        self.positions.append(self.infield_cnrs[first])
        self.positions.append(self.infield_cnrs[second])
        self.positions.append(self.infield_cnrs[third])
        #print(self.positions)

        return image
            
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
        
        print("#: " + str(len(self.players)))

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

        approx = infieldFittingRoutines.approxPolyDP_adaptive(contour, nsides=4)
        return infieldFittingRoutines.hough_fit(contour, nsides=4, approx_fit=approx, image_frame=image_frame)

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
        if self.positions is not None and len(self.positions) != 0:
            b = 0
            add = int(255 / len(self.positions))
            for pos in self.positions:
                cv2.drawMarker(output_frame, tuple(pos), (b, 0, 0), cv2.MARKER_CROSS, 20, 5)
                b+=add

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