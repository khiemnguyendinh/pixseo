/// Output widths offered in the Finder menu and the Quick Save panel (pixels).
public enum SizePresets {
    public static let widths = [1080, 1440, 1600, 1920, 3840]

    /// The largest preset smaller than `width`, used to suggest a smaller size when a file
    /// can't reach the requested byte limit.
    public static func nextSmaller(than width: Int) -> Int? {
        widths.last { $0 < width }
    }
}
