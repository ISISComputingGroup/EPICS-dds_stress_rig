import unittest

from parameterized import parameterized
from utils.channel_access import ChannelAccess
from utils.ioc_launcher import get_default_ioc_dir
from utils.test_modes import TestModes
from utils.testing import get_running_lewis_and_ioc, skip_if_devsim

DEVICE_PREFIX = "DDSSTRES_01"


IOCS = [
    {
        "name": DEVICE_PREFIX,
        "directory": get_default_ioc_dir("DDSSTRES"),
        "macros": {"IPADDR":"127.0.0.1", "VI_PATH":"C:/instrument/dev/ibex_vis/"},
        "emulator": "dds_stress_rig",
    },
]


TEST_MODES = [TestModes.RECSIM]


class DdsStressRigTests(unittest.TestCase):
    """
    Tests for the DDS_Stress_rig IOC.
    """
    def setUp(self):
        self._lewis, self._ioc = get_running_lewis_and_ioc("dds_stress_rig", DEVICE_PREFIX)
        self.ca = ChannelAccess(device_prefix=DEVICE_PREFIX)

    @parameterized.expand([("upper_limit", 1, [-1, 0, 0, 0, 0, 0, 0], "True", "False", "UPPER", "LOWER"),
                           ("lower_limit", -1, [1, 0, 0, 0, 0, 0, 0], "False", "True", "LOWER", "UPPER")])
    @skip_if_devsim("Requires use of SIM Record")
    def test_WHEN_start_sequence_THEN_correct_limit(self, _, target, elong, ulimit, llimit, set, unset):
        self.ca.set_pv_value("LOWER_LIMIT:SP", 0)
        self.ca.set_pv_value("UPPER_LIMIT:SP", 0)

        self.ca.set_pv_value("SIM:ARRAY", elong)
        self.ca.set_pv_value("TRGT", target)
        self.ca.set_pv_value("START.PROC", 1)
        self.ca.assert_that_pv_is("MEAS:STOP:SP", "False")
        self.ca.assert_that_pv_is("MOT:MODE:SP", "Tacho")
        self.ca.assert_that_pv_is("ULIMIT:ENABLED:SP", ulimit)
        self.ca.assert_that_pv_is("LLIMIT:ENABLED:SP", llimit)
        self.ca.assert_that_pv_is(f"{set}_LIMIT:SP", target)
        self.ca.assert_that_pv_is(f"{unset}_LIMIT:SP", 0)

    @skip_if_devsim("Requires use of SIM Record")
    def test_WHEN_array_val_THEN_split_properly(self):
        elong = 1.23
        load = 3.34
        time = 87.2
        self.ca.set_pv_value("SIM:ARRAY", [elong, load, time, 0, 0, 0, 0])
        self.ca.assert_that_pv_is("ARRAY", [elong, load, time, 0, 0, 0, 0])

        self.ca.assert_that_pv_is("ELONG", elong)
        self.ca.assert_that_pv_is("LOAD", load)
        self.ca.assert_that_pv_is("TIME", time)

        self.ca.set_pv_value("SIM:ARRAY", [0, 0, 0, 0, 0, 0, 0])

