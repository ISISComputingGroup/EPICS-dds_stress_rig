TOP=..
include $(TOP)/configure/CONFIG
#=======================================

# Install .dbd and .db files
DB += tensile_stress_rig_internal.db
DB += lvremote_dds_tensile_stress_rig.db
DBD += start_or_load.dbd

# Sequence file
LIBRARY_IOC = dds_stress_rig
dds_stress_rig_SRCS += start_or_load.st
dds_stress_rig_LIBS += seq pv
dds_stress_rig_LIBS += $(EPICS_BASE_IOC_LIBS)

#=======================================
include $(TOP)/configure/RULES
