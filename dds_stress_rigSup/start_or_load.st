#include "ibexSeqPVmacros.h"


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
PV(float, target, "{P}LOAD:SP", Monitor);
PV(float, upperLimit, "{P}UPPER_LIMIT:SP", NoMon);
PV(float, lowerLimit, "{P}LOWER_LIMIT:SP", NoMon);
PV(int, startMeasurement, "{P}MEAS:START:SP", NoMon);
PV(int, start, "{P}START", Monitor);
PV(int, load, "{P}SET_LOAD", Monitor);
int preMeasure = 0;
enum mode {noMode = 0, loadMode = 1, startMode = 2};
%{
  static const char* const PROGRAM_NAME = "start_or_load.st";

  /* This needs to be a macro as the call to pvIndex has to happen from SNL code, not C code. */
  /* See https://www-csr.bessy.de/control/SoftDist/sequencer/EscapeToC.html?highlight=pvindex#calling-pv-functions-from-c */
  #define G3HP_TRANSITION_TO_STATE(x) g3hp_state_transition(ssId, pVar, pvIndex(statemachine_state), (x))
  
  static void g3hp_state_transition(SS_ID ssId, struct seqg_vars* const pVar, CH_ID index, const char* const new_state_name);
}%

ss start_or_load
{
    state neutral
    {
        entry {G3HP_TRANSITION_TO_STATE("neutral");}
    
        when (start == 1 || load == 1) {
            stopMeasurement = 1;
            if (start == 1){
                mode = start
            }else{
                mode = load
            }
            
            PVPUT(stopMeasurement);
            
        } state stopDelay
    }

    state stopDelay 
    {
        entry {G3HP_TRANSITION_TO_STATE("stopDelay");}
        when (delay(0.4) && preMeasure == 0){

        } state clearLimit
        when (delay(0.4) && preMeasure == 1){
            preMeasure = 0
        } state startState
    }
    
    state clearLimit
    {
        entry
        { 
            G3HP_TRANSITION_TO_STATE("clearLimit");
            setChannel = mode;
            PVPUT(setChannel);
        }

        when (getChannel == 1 && setChannel == 1){
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 0;
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        } state s1
        when (getChannel == 2 && setChannel == 2){
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 0;
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        } state l1
    }

    state s1
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("s1");
        }   

        when(getLowLimitEnabled == 0 && getUpLimitEnabled == 0){
            setChannel = 2;
            PVPUT(setChannel);
        } state resetLimit
    }

    state l1
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("l1");
        }   

        when(getLowLimitEnabled == 0 && getUpLimitEnabled == 0){
            setChannel = 1;
            PVPUT(setChannel);
        } state resetLimit
    }

    state resetLimit
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("resetLimit");
        }   

        when(getChannel == setChannel && mode == start){
            setUpLimitEnabled = getUpLimitEnabled;
            setLowLimitEnabled = getUpLimitEnabled;
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        } state s2
        when(getChannel == setChannel && mode == load){
            setUpLimitEnabled = getUpLimitEnabled;
            setLowLimitEnabled = getUpLimitEnabled;
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        } state l2
    }

    state s2
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("s2");
            setMotorMode = 0;
            setModeStat = 0;
            PVPUT(setMotorMode);
            PVPUT(setModeStat);
        }   

        when(getModeStat == setModeStat && target>elong){
            setModeStat = 1
            PVPUT(setModeStat)
        } state startGreater
        when(getModeStat == setModeStat && target<=elong){
            setModeStat = 1;
            PVPUT(setModeStat);
        } state startLesser
    }

    state l2
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("l2");
            setMotorMode = 0;
            setModeStat = 0;
            PVPUT(setMotorMode);
            PVPUT(setModeStat);
        }   

        when(getModeStat == setModeStat){
            setModeStat = 1
            PVPUT(setModeStat)
        } state l3
    }

    state l3
    {
         entry
        { 
            G3HP_TRANSITION_TO_STATE("l3");
            lowerLimit = load;
            upperLimit = load;
            setUpLimitEnabled = 1;
            setLowLimitEnabled = 1;
            PVPUT(upperLimit);
            PVPUT(lowerLimit);
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        }   

        when(getLowLimitEnabled == 1 && getUpLimitEnabled == 1){
        } state stopDelay
    }

    state startGreater
    {
        entry
        {
            G3HP_TRANSITION_TO_STATE("startGreater");
            upperLimit = target;
            setUpLimitEnabled = 1;
            setLowLimitEnabled = 0;
            PVPUT(upperLimit);
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        }

        when(getUpLimitEnabled == setUpLimitEnabled && getLowLimitEnabled == setLowLimitEnabled)
        {
            preMeasure = 1
        } state stopDelay
    }

    state startLesser
    {
        entry
        {
            G3HP_TRANSITION_TO_STATE("startLesser");
            lowerLimit = target;
            setUpLimitEnabled = 0;
            setLowLimitEnabled = 1;
            PVPUT(lowerLimit);
            PVPUT(setUpLimitEnabled);
            PVPUT(setLowLimitEnabled);
        }

        when(getUpLimitEnabled == setUpLimitEnabled && getLowLimitEnabled == setLowLimitEnabled)
        {
            preMeasure = 1
        } state stopDelay
    }

    state startState
    {
        entry
        {
            G3HP_TRANSITION_TO_STATE("startState");
            startMeasurement = 1;
            PVPUT(startMeasurement);
        }
        when(delay(0.4)){
            mode = noMode;
        } state neutral
    }
}