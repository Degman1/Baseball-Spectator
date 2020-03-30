#!/usr/bin/env python3

import os.path
import cv2
import numpy
import infieldFittingRoutines

class PlayerFinder(object):
    def __init__(self):
        self.lower_green = numpy.array((17, 50, 20), dtype=numpy.uint8)
        self.upper_green = numpy.array((72, 255, 242), dtype=numpy.uint8)

        self.lower_brown = numpy.array((7, 80, 25), dtype=numpy.uint8)
        self.upper_brown = numpy.array((27, 255, 255), dtype=numpy.uint8)

        self.lower_dark_brown = numpy.array((2, 93, 25), dtype=numpy.uint8)
        self.upper_dark_brown = numpy.array((10, 175, 150), dtype=numpy.uint8)

        self.player_contours = None
        self.top_players = None
        self.players = None

        self.infield_contours = None
        self.top_infield = None
        self.infield = None
        self.infield_cnrs = None

        self.fieldDraw = None

        return

    def reset_variables(self):
        self.player_contours = None
        self.top_players = None
        self.players = None

        self.infield_contours = None
        self.top_infield = None
        self.infield = None
        self.infield_cnrs = None

    def process_image(self, image):
        '''Main image processing routine'''
        
        #converting into hsv image
        self.reset_variables()
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

        #Define a mask ranging from lower to uppper
        mask_green = cv2.inRange(hsv, self.lower_green, self.upper_green)
        mask_brown = cv2.inRange(hsv, self.lower_brown, self.upper_brown)
        mask_dark_brown = cv2.inRange(hsv, self.lower_dark_brown, self.upper_dark_brown)

        mask = cv2.bitwise_or(mask_green, mask_brown)
        mask = cv2.bitwise_or(mask, mask_dark_brown)
        
        im = self.get_infield_cnrs(mask_green, image)    #pass in image for quad fit debugging
        if im is not None:
            image = im      #updates output for drawing debug
        self.get_player_contours(mask)
        print("Thank you, next...")
 
        return image
    
    def get_infield_cnrs(self, mask, image):    #array return order: home, first, second, third
        erosion = cv2.erode(mask, numpy.ones((4, 4), numpy.uint8), iterations = 1)
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
        
        self.infield = self.infield['contour']

        # to find quadrilateral using hough_fit method
        cnrs = self.quad_fit(self.infield, image_frame=image)
        if cnrs is not None:
            self.infield_cnrs = numpy.array(cnrs).astype(int)
        
        return image
            
    def get_player_contours(self, mask):
        erosion = cv2.erode(mask, numpy.ones((5,5), numpy.uint8), iterations = 1)   
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

        self.fieldDraw = field['contour']

        self.top_players = [x['contour'] for x in contour_list]
        
        self.players = []

        for player in contour_list:
            width = player['widths'][0]
            height = player['widths'][1]
            ratio = height / width

            if ratio >= 0.8 and ratio <= 3.0:# and cv2.contourArea(player['contour']) > 200:
                self.players.append(player)

        if len(self.players) == 0:
            self.players = None
            return
        
        self.players = [x['contour'] for x in self.players]

    def isCandidatePlayerOnField(self, candidateCenterPt, fieldInfo):
        width = fieldInfo['widths'][0] / 2
        height = fieldInfo['widths'][1] / 2
        centerx = fieldInfo['center'][0]
        centery = fieldInfo['center'][1]

        #if center of candidate player is not even in the field's bounding box, definitely is not inside the contour -- more effiecient in best cases
        if candidateCenterPt[0] >= centerx + width or candidateCenterPt[0] <= centerx - width or candidateCenterPt[1] <= centery - height and candidateCenterPt[1] >= centery + height:
            return False
        
        sameXvalue = []     #array of x values that lie at the same y value as the candidate
        sameYvalue = []     #array of y values that lie at the same x value as the candidate

        for pt in fieldInfo['contour']:
            if pt[0][1] == centerx:
                sameXvalue.append(pt[0][0])
            if pt[0][0] == centery:
                sameYvalue.append(pt[0][1])

        if len(sameXvalue) >= 2 and len(sameYvalue) >= 2 and centerx > min(sameXvalue) and centerx < max(sameXvalue) and centery > min(sameYvalue) and centery < max(sameYvalue):
            return True
        
        return False

    def area_cut(self, cnts, min_area, max_area):
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
        """
        #green
        if self.infield is not None:
            cv2.drawContours(output_frame, [self.infield], -1, (0, 255, 0), 3)

        #yellow
        if self.infield_cnrs is not None:
            for cnr in self.infield_cnrs:
                cv2.drawMarker(output_frame, tuple(cnr), (0, 255, 255), cv2.MARKER_CROSS, 20, 5)

        if self.fieldDraw is not None:
            cv2.drawContours(output_frame, [self.fieldDraw], -1, (255, 255, 0), 2)
        
        return output_frame


def process_files(processor, input_files, output_dir):
    '''Process the files and output the marked up image'''
    import os.path

    for image_file in input_files:
        bgr_frame = cv2.imread(image_file)

        #-----------------------------resize:
        new_height = 1080   # This is the pixel dimensions of the standard iphone 8 camera setting (1080p HD)
        # Makes sure all images are the same height --> same relative player sizes so that contour cuttoffs can be accurate

        scale_percent = new_height / bgr_frame.shape[0]
        width = int(bgr_frame.shape[1] * scale_percent)
        height = int(bgr_frame.shape[0] * scale_percent)

        resized = cv2.resize(bgr_frame, (width, height), interpolation = cv2.INTER_AREA)
        #--------------------------------------------

        testing_output = processor.process_image(resized)

        markup = processor.prepare_output_image(resized)

        outfile = os.path.join(output_dir, os.path.basename(image_file))
        # print('{} -> {}'.format(image_file, outfile))
        cv2.imwrite(outfile, markup)

        # cv2.imshow("Window", bgr_frame)
        # q = cv2.waitKey(-1) & 0xFF
        # if q == ord('q'):
        #     break
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