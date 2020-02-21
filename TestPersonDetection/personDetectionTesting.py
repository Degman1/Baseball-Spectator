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
        self.contour_min_area = 100

        self.contours = None
        self.top_contours = None

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
        
        #res = cv2.bitwise_and(image,image, mask=mask)

        erosion = cv2.erode(mask, numpy.ones((7,7), numpy.uint8), iterations = 1)

        return erosion
        """
         #find contours in threshold image     
        _, self.contours, _ = cv2.findContours(res_gray, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        print(len(self.contours))

        contour_list = []
        for c in self.contours:
            center, widths = self.contour_center_width(c)
            area = widths[0] * widths[1]
            if area > self.contour_min_area:
                contour_list.append({'contour': c, 'center': center, 'widths': widths, 'area': area})
        
        # Sort the list of contours from biggest area to smallest
        contour_list.sort(key=lambda c: c['area'], reverse=True)

        self.top_contours = [x['contour'] for x in contour_list]
        
        print(len(contour_list))"""
    
    def contour_center_width(self, contour):
        '''Find boundingRect of contour, but return center and width/height'''

        x, y, w, h = cv2.boundingRect(contour)
        return (x + int(w / 2), y + int(h / 2)), (w, h)

    def test_candidate_contour(self, contour_entry):
        cnt = contour_entry['contour']

        real_area = cv2.contourArea(cnt)
        # print('areas:', real_area, contour_entry['area'], real_area / contour_entry['area'])
        if real_area / contour_entry['area'] > 0.5:
            hull = cv2.convexHull(cnt)
            # hull_fit contains the corners for the contour
            hull_fit = PlayerFinder.quad_fit(hull, self.approx_polydp_error)

            return hull_fit

        return None

    def prepare_output_image(self, input_frame):
        '''Prepare output image for drive station. Draw the found target contour.'''

        output_frame = input_frame.copy()

        # Draw the contour on the image

        if self.contours is not None:
            cv2.drawContours(output_frame, self.contours, -1, (255, 0, 0), 2)

        if self.top_contours is not None:
            cv2.drawContours(output_frame, self.top_contours, -1, (0, 0, 255), 2)

        return output_frame

def process_files(processor, input_files, output_dir):
    '''Process the files and output the marked up image'''
    import os.path

    for image_file in input_files:
        # print()
        # print(image_file)
        bgr_frame = cv2.imread(image_file)
        result = processor.process_image(bgr_frame)

        markup = processor.prepare_output_image(bgr_frame)

        outfile = os.path.join(output_dir, os.path.basename(image_file))
        # print('{} -> {}'.format(image_file, outfile))
        cv2.imwrite(outfile, result)

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