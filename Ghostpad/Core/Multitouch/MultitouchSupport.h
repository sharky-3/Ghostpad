#import <CoreFoundation/CoreFoundation.h>

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

typedef struct {
    int frame;
    double timestamp;
    int pathIndex;
    int state;
    int fingerID;
    int handID;
    MTVector normalized;
    float zTotal;
    int field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;
    int field14;
    int field15;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;

typedef void (*MTContactCallbackFunction)(MTDeviceRef device, MTTouch *touches, int count, double timestamp, int frame);

CFMutableArrayRef MTDeviceCreateList(void) CF_RETURNS_RETAINED;
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTUnregisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTDeviceStart(MTDeviceRef device, int mode);
void MTDeviceStop(MTDeviceRef device);
bool MTDeviceIsBuiltIn(MTDeviceRef device);
bool MTDeviceIsRunning(MTDeviceRef device);
OSStatus MTDeviceGetSensorSurfaceDimensions(MTDeviceRef device, int *width, int *height);
