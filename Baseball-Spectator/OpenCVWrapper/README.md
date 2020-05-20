I used this link to integrate swift with OpenCV in C++: 
        https://www.timpoulsen.com/2019/using-opencv-in-an-ios-app.html

The OpenCVWrapper.h file is responsible for creating the headers of the OpenCVWrapper class and its class mathods
The OpenCVWrapper.mm file is responsible for the body of the functions in the OpenCVWrapper class

To use a method from the OpenCVWrapper class in swift, simple use this format:
        OpenCVWrapper.someMethod(someParameters)
