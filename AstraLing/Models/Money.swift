import Foundation

extension Int {
    /// Formats an integer rupiah amount with Indonesian thousand separators, e.g. 150000 → "150.000".
    var formattedIDR: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Returns a full rupiah string, e.g. 150000 → "Rp150.000".
    var rupiah: String { "Rp\(formattedIDR)" }
}
