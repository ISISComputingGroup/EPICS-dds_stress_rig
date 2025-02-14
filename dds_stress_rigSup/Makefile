TOP=..
include $(TOP)/configure/CONFIG
#=======================================

# Install .dbd and .db files
DB += tensile_stress_rig_internal.db
DB += lvremote_dds_tensile_stress_rig.db
DBD += start_or_load.dbd

# Sequence file
DDS_STRESS_RIG_SRCS += start_or_load.st
LIBRARY_IOC = dds_stress_rig
DDS_STRESS_RIG_LIBS += seq pv
DDS_STRESS_RIG_LIBS += $(EPICS_BASE_IOC_LIBS)

#=======================================
include $(TOP)/configure/RULES
