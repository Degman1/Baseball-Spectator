//
//  Timer.mm
//  Baseball-Spectator
//
//  Created by David Gerard on 5/23/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#include <chrono>
#include <ctime>

using namespace std;

//Timer to time the image processing
class Timer {
    public:
    void start() {
        m_StartTime = chrono::system_clock::now();
        m_bRunning = true;
    }
    
    void stop() {
        m_EndTime = chrono::system_clock::now();
        m_bRunning = false;
    }
    
    double elapsedMilliseconds() {
        chrono::time_point<std::chrono::system_clock> endTime;
        
        if (m_bRunning) { endTime = chrono::system_clock::now(); }
        else { endTime = m_EndTime; }
        
        return chrono::duration_cast<std::chrono::milliseconds>(endTime - m_StartTime).count();
    }
    
    double elapsedSeconds() {
        return elapsedMilliseconds() / 1000.0;
    }

    private:
    chrono::time_point<std::chrono::system_clock> m_StartTime;
    chrono::time_point<std::chrono::system_clock> m_EndTime;
    bool m_bRunning = false;
};
