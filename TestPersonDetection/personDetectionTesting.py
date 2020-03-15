#!/usr/bin/env python3

import os.path
import cv2
import numpy

class PlayerFinder(object):
    def __init__(self):
        self.lower_green = numpy.array((17, 50, 20), dtype=numpy.uint8)
        self.upper_green = numpy.array((72, 255, 242), dtype=numpy.uint8)

        self.lower_brown = numpy.array((7, 80, 25), dtype=numpy.uint8)
        self.upper_brown = numpy.array((27, 255, 255), dtype=numpy.uint8)

        self.lower_dark_brown = numpy.array((2, 93, 25), dtype=numpy.uint8)
        self.upper_dark_brown = numpy.array((10, 175, 150), dtype=numpy.uint8)
        """
        self.lower_dark_green = numpy.array((1, 45, 14), dtype=numpy.uint8)
        self.upper_dark_green = numpy.array((72, 255, 242), dtype=numpy.uint8)"""

        # pixel area of the bounding rectangle - just used to remove stupidly small regions
        self.contour_min_area = 300    # TODO MUST change these numbers based on the camera resolution that we choose for the iphone's camera!!
        self.contour_max_area = 2000

        self.player_contours = None
        self.top_players = None
        self.players = None

        self.infield_contours = None
        self.top_infield = None
        self.infield = None
        self.infield_cnrs = None

        return

    @staticmethod
    def contour_center_width(contour):
        '''Find boundingRect of contour and return center, width, and height'''

        x, y, w, h = cv2.boundingRect(contour)
        return (x + int(w / 2), y + int(h / 2)), (w, h)

    @staticmethod
    def quad_fit(contour, approx_dp_error):
        '''Simple polygon fit to contour with error related to perimeter'''

        peri = cv2.arcLength(contour, True)
        return cv2.approxPolyDP(contour, approx_dp_error * peri, True)

    def process_image(self, image):
        '''Main image processing routine'''
        
        #converting into hsv image
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

        #Define a mask ranging from lower to uppper
        mask_green = cv2.inRange(hsv, self.lower_green, self.upper_green)
        mask_brown = cv2.inRange(hsv, self.lower_brown, self.upper_brown)
        mask_dark_brown = cv2.inRange(hsv, self.lower_dark_brown, self.upper_dark_brown)

        mask = cv2.bitwise_or(mask_green, mask_brown)
        mask = cv2.bitwise_or(mask, mask_dark_brown)
        
        #res = cv2.bitwise_and(img,img, mask=mask)

        self.get_infield_cnrs(mask_green)
        #self.get_player_contours(mask)
 
        return image
    
    def get_infield_cnrs(self, mask):
        erosion = cv2.erode(mask, numpy.ones((4,4), numpy.uint8), iterations = 1)
        _, self.infield_contours, _ = cv2.findContours(erosion, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        infield_contour_list = self.area_cut(self.infield_contours, 15000, 200000)
        #self.infield = min(infield_contour_list, key=lambda x:x['area'])['contour']
        self.top_infield = [x['contour'] for x in infield_contour_list]

        hulls = [cv2.convexHull(x) for x in self.top_infield]
        self.infield = hulls[0]
        #if len(hulls) == 1:  #already found the infield
        cnrs = self.get_cnrs(hulls[0])
        #print(self.infield)
        #rect = cv2.minAreaRect(cnrs)
        #self.infield = numpy.array(cv2.boxPoints(rect)).astype(int)
        self.infield_cnrs = cnrs

        #print(self.infield)

        #return cnrs

    def get_cnrs(self, c):
        formatted = numpy.zeros((4, 1, 2)).astype(int)
        formatted[0] = min(c, key=lambda x: x[0][0])[0]   #min x coord
        formatted[1] = min(c, key=lambda x: x[0][1])[0]   #min y coord (highest)
        formatted[2] = max(c, key=lambda x: x[0][0])[0]   #max x coord
        formatted[3] = max(c, key=lambda x: x[0][1])[0]   #max y coord (lowest)

        return formatted
            
    def get_player_contours(self, mask):
        erosion = cv2.erode(mask, numpy.ones((7,7), numpy.uint8), iterations = 1)   
        _, self.contours, _ = cv2.findContours(erosion, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        print("Before: " + str(len(self.contours)))

        contour_list = self.area_cut(self.contours, self.contour_min_area, self.contour_max_area)

        self.top_players = [x['contour'] for x in contour_list]
        
        print("After 1: " + str(len(contour_list)))

        self.players = self.ratio_H2W_cut(self.top_players, 0.8, 3.0)

        print("After 2: " + str(len(self.players)) + "\n")

    """def area_cut(self, cnts, min_area, max_area, min_real_area = -1, max_real_area = -1):
        contour_list = []
        for c in cnts:
            center, widths = self.contour_center_width(c)
            area = widths[0] * widths[1]

            if (min_real_area == -1 or max_real_area == -1) and area > min_area and area < max_area:
                contour_list.append({'contour': c, 'center': center, 'widths': widths, 'area': area})
            elif min_real_area != -1 and max_real_area != -1 and area > min_area and area < max_area and min_real_area > min_area and real_area < max_real_area:
                contour_list.append({'contour': c, 'center': center, 'widths': widths, 'area': area})
        
        # Sort the list of contours from biggest area to smallest
        contour_list.sort(key=lambda c: c['widths'][0] * c['widths'][1], reverse=True)

        return contour_list"""

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

    def ratio_H2W_cut(self, cnts, min_ratio, max_ratio):
        contour_list = []
        for c in cnts:
            height = c['widths'][1]
            width = c['widths'][0]
            ratio = height / width
            #print("ratio: " + str(ratio))
            #print("w, h: " + str(width) + ", " + str(height))
            #print("------")
            if ratio >= min_ratio and ratio <= max_ratio:
                contour_list.append(c)
        
        return contour_list

    def contour_center_width(self, contour):
        '''Find boundingRect of contour, but return center and width/height'''

        x, y, w, h = cv2.boundingRect(contour)
        return (x + int(w / 2), y + int(h / 2)), (w, h)

    def prepare_output_image(self, input_frame):
        '''Prepare output image for drive station. Draw the found target contour.'''

        output_frame = input_frame.copy()

        # Draw the contour on the image
        #blue
        if self.player_contours is not None:
            cv2.drawContours(output_frame, self.contours, -1, (255, 0, 0), 1)

        #green
        if self.top_players is not None:
            cv2.drawContours(output_frame, self.top_contours, -1, (0, 255, 0), 2)
        
        #red
        if self.players is not None:
            cv2.drawContours(output_frame, self.found_players, -1, (0, 0, 255), 3)
        
        #blue
        if self.infield_contours is not None:
            cv2.drawContours(output_frame, self.infield_contours, -1, (255, 0, 0), 1)

        #blue
        if self.top_infield is not None:
            cv2.drawContours(output_frame, self.top_infield, -1, (0, 255, 0), 2)

        #red
        if self.infield is not None:
            cv2.drawContours(output_frame, self.infield, -1, (0, 0, 255), 2)

        #red
        if self.infield_cnrs is not None:
            for cnr in self.infield_cnrs:
                cv2.drawMarker(output_frame, tuple(cnr[0]), (0, 0, 255), cv2.MARKER_CROSS, 20, 5)
        
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