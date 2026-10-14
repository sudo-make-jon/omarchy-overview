from pathlib import Path
import unittest


QML = Path(__file__).resolve().parents[1] / "WindowOverview.qml"


class PointerFocusPolicyTests(unittest.TestCase):
    def test_overview_primes_keyboard_focus_then_releases_it_for_pointer_input(self):
        source = QML.read_text()
        self.assertIn("property bool focusPrimed: false", source)
        self.assertRegex(source, r"interval:\s*75")
        self.assertIn("WlrKeyboardFocus.Exclusive", source)
        self.assertIn("WlrKeyboardFocus.OnDemand", source)
        self.assertRegex(
            source,
            r"return root\.focusPrimed \? WlrKeyboardFocus\.OnDemand : WlrKeyboardFocus\.Exclusive",
        )
        self.assertRegex(source, r"focusPrimeTimer\.restart\(\)")
        self.assertRegex(source, r"focusPrimeTimer\.stop\(\)")

    def test_non_primary_screens_do_not_take_keyboard_focus(self):
        source = QML.read_text()
        self.assertRegex(
            source,
            r"modelData\s*!==\s*Quickshell\.screens\[0\]\s*\|\|\s*!root\.opened[\s\S]*?return\s+WlrKeyboardFocus\.None",
        )

    def test_open_with_no_windows_cancels_any_pending_focus_prime(self):
        source = QML.read_text()
        open_body = source.split("function open(payloadJson)", 1)[1].split(
            "function close()", 1
        )[0]
        self.assertRegex(
            open_body,
            r"if\s*\(windows\.length === 0\)\s*\{\s*root\.close\(\)",
        )


if __name__ == "__main__":
    unittest.main()
