program start_or_load("P")

#include "ibexSeqPVmacros.h"
%% #include "seq_snc.h"
%% #include "epicsTime.h"
%% #include "string.h"
%% #include "math.h"
%% #include "errlog.h"
%% #include "alarm.h"

option +d;
option +r;
option +s;


/* Debugging: current state of this state machine */
PV(string, statemachine_state, "{P}STATEMACHINE:STATE", NoMon);

PV(int, stopMeasurement, "{P}MEAS:STOP:SP", NoMon);
PV(int, setChannel, "{P}CHANNEL:SP", NoMon);
PV(int, getChannel, "{P}CHANNEL", Monitor);
PV(int, setUpLimitEnabled, "{P}ULIMIT:ENABLED:SP", NoMon);
PV(int, getUpLimitEnabled, "{P}ULIMIT:ENABLED", Monitor);
PV(int, setLowLimitEnabled, "{P}LLIMIT:ENABLED:SP", NoMon);
PV(int, getLowLimitEnabled, "{P}LLIMIT:ENABLED", Monitor);
PV(int, setMotorMode, "{P}MOT:MODE:SP", NoMon);
PV(int, getMotorMode, "{P}MOT:MODE", Monitor);
PV(int, setModeStat, "{P}MODE:STAT:SP", NoMon);
PV(int, getModeStat, "{P}MODE:STAT", Monitor);
PV(float, target, "{P}TRGT", Monitor);
PV(float, elong, "{P}ELONG", Monitor);
PV(float, load, "{P}LOAD:SP", Monitor);
PV(float, upperLimit, "{P}UPPER_LIMIT:SP", NoMon);
PV(float, lowerLimit, "{P}LOWER_LIMIT:SP", NoMon);
PV(int, startMeasurement, "{P}MEAS:START:SP", NoMon);
PV(int, start, "{P}START", Monitor);
PV(int, setLoad, "{P}SET_LOAD", Monitor);
PV(int, setSpeed, "{P}CHANGE_SPEED", Monitor);
PV(int, setSpeedMode, "{P}MODE:SPEED:SP", NoMon);
PV(int, setControl, "{P}CONTROL:SPEED:SP", NoMon);
PV(int, setDirection, "{P}DIRECTION:SPEED:SP", NoMon);
PV(int, getSpeedMode, "{P}MODE:SPEED", Monitor);
PV(int, getControl, "{P}CONTROL:SPEED", Monitor);
PV(int, getDirection, "{P}DIRECTION:SPEED", Monitor);
PV(float, speedVal, "{P}_SPEED:SP", NoMon);
PV(float, setSpeedVal, "{P}SPEED:SP", Monitor);
PV(float, getSpeedVal, "{P}_SPEED", Monitor);
PV(int, setSpeedSP, "{P}SPEED:SET:SP", NoMon);
int preMeasure = 0;
%{ 
    enum{noMode = 0, loadMode = 1, startMode = 2} mode=noMode;
}%
%{
  static const char* const PROGRAM_NAME = "start_or_load.st";

  /* This needs to be a macro as the call to pvIndex has to happen from SNL code, not C code. */
  /* See https://www-csr.bessy.de/control/SoftDist/sequencer/EscapeToC.html?highlight=pvindex#calling-pv-functions-from-c */
  #define DDS_STRESS_TRANSITION_TO_STATE(x) dds_stress_state_transition(ssId, pVar, pvIndex(statemachine_state), (x))
  
  static void dds_stress_state_transition(SS_ID ssId, struct seqg_vars* const pVar, CH_ID index, const char* const new_state_name);
}%

ss start_or_load
{
    state neutral
    {
        entry {DDS_STRESS_TRANSITION_TO_STATE("neutral");}
    
        when (start == 1 || setLoad == 1) {
            stopMeasurement = 1;
            if (start == 1){
                mode = startMode;
            }else{
                mode = loadMode;
            }
            
            pvPut(stopMeasurement);
            
        } state stopDelay
        when (setSpeed == 1) {
            setSpeed = 0;
            pvPut(setSpeed);
        } state speed1
    }

    state speed1
    {
        entry 
        {
            DDS_STRESS_TRANSITION_TO_STATE("speed1");
            setSpeedMode = 1;
            setControl = 0;
            setDirection = 0;
            pvPut(setSpeedMode);
            pvPut(setControl);
            pvPut(setDirection);
        }

        when (getDirection == 0 && getSpeedMode == 1 && getControl == 0){
            speedVal = setSpeedVal;
            pvPut(speedVal);
        } state speed2
    }

    state speed2
    {
        entry{DDS_STRESS_TRANSITION_TO_STATE("speed2");}
        when(getSpeedVal == speedVal){
            setSpeedSP = 1;
            pvPut(setSpeedSP);
        } state speed3
    }

    state speed3
    {
        entry
        {
            DDS_STRESS_TRANSITION_TO_STATE("speed3");
            setDirection = 2;
            pvPut(setDirection);
        }
        when(getDirection == setDirection){
            setSpeedSP = 1;
            pvPut(setSpeedSP);
        } state neutral
        
    }

    state stopDelay 
    {
        entry {DDS_STRESS_TRANSITION_TO_STATE("stopDelay");}
        when (delay(0.4) && preMeasure == 0){

        } state clearLimit
        when (delay(0.4) && preMeasure == 1){
            preMeasure = 0;
        } state startState
    }
    
    state clearLimit
    {
        entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("clearLimit");
            if (mode == loadMode) {
                setChannel = startMode;
            }else{
                setChannel = loadMode;
            }
            
            pvPut(setChannel);
        }

        when (getChannel == loadMode && setChannel == loadMode){
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 0;
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        } state start1
        when (getChannel == startMode && setChannel == startMode){
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 0;
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        } state load1
    }

    state start1
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("start1");
        }   

        when(getLowLimitEnabled == 0 && getUpLimitEnabled == 0){
            setChannel = 2;
            pvPut(setChannel);
        } state resetLimit
    }

    state load1
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("load1");
        }   

        when(getLowLimitEnabled == 0 && getUpLimitEnabled == 0){
            setChannel = 1;
            pvPut(setChannel);
        } state resetLimit
    }

    state resetLimit
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("resetLimit");
        }   

        when(getChannel == setChannel && mode == startMode){
            setUpLimitEnabled = getUpLimitEnabled;
            setLowLimitEnabled = getUpLimitEnabled;
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        } state start2
        when(getChannel == setChannel && mode == loadMode){
            setUpLimitEnabled = getUpLimitEnabled;
            setLowLimitEnabled = getUpLimitEnabled;
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        } state load2
    }

    state start2
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("start2");
            setMotorMode = 0;
            setModeStat = 0;
            pvPut(setMotorMode);
            pvPut(setModeStat);
        }   

        when(getModeStat == setModeStat && target>elong){
            setModeStat = 1;
            pvPut(setModeStat);
        } state startGreater
        when(getModeStat == setModeStat && target<=elong){
            setModeStat = 1;
            pvPut(setModeStat);
        } state startLesser
    }

    state load2
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("load2");
            setMotorMode = 0;
            setModeStat = 0;
            pvPut(setMotorMode);
            pvPut(setModeStat);
        }   

        when(getModeStat == setModeStat){
            setModeStat = 1;
            pvPut(setModeStat);
        } state load3
    }

    state load3
    {
         entry
        { 
            DDS_STRESS_TRANSITION_TO_STATE("load3");
            lowerLimit = load;
            upperLimit = load;
            setUpLimitEnabled = 1;
            setLowLimitEnabled = 1;
            pvPut(upperLimit);
            pvPut(lowerLimit);
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        }   

        when(getLowLimitEnabled == 1 && getUpLimitEnabled == 1){
            preMeasure = 1;
        } state stopDelay
    }

    state startGreater
    {
        entry
        {
            DDS_STRESS_TRANSITION_TO_STATE("startGreater");
            upperLimit = target;
            setUpLimitEnabled = 1;
            setLowLimitEnabled = 0;
            pvPut(upperLimit);
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        }

        when(getUpLimitEnabled == setUpLimitEnabled && getLowLimitEnabled == setLowLimitEnabled)
        {
            preMeasure = 1;
        } state stopDelay
    }

    state startLesser
    {
        entry
        {
            DDS_STRESS_TRANSITION_TO_STATE("startLesser");
            lowerLimit = target;
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 1;
            pvPut(lowerLimit);
            pvPut(setUpLimitEnabled);
            pvPut(setLowLimitEnabled);
        }

        when(getUpLimitEnabled == setUpLimitEnabled && getLowLimitEnabled == setLowLimitEnabled)
        {
            preMeasure = 1;
        } state stopDelay
    }

    state startState
    {
        entry
        {
            DDS_STRESS_TRANSITION_TO_STATE("startState");
            startMeasurement = 1;
            pvPut(startMeasurement);
        }
        when(delay(0.4)){
            mode = noMode;
        } state neutral
    }
}

%{
    /**
     * Called on any state transitions that occur in the state machine - primarily for debugging.
     */
    static void dds_stress_state_transition(SS_ID ssId, struct seqg_vars* const pVar, CH_ID index, const char* const new_state_name)
    {
      strncpy(pVar->statemachine_state, new_state_name, MAX_STRING_SIZE);
      seq_pvPut(ssId, index, SYNC);
      errlogSevPrintf(errlogInfo, "%s:  Entering state %s\n", PROGRAM_NAME, new_state_name);
    }
  }%
