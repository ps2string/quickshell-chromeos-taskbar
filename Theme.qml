import QtQuick

pragma Singleton

// Static geometry and font tokens.
// Dynamic colors are in services/ColorService.qml (live from matugen).
QtObject {
    // Fonts
    readonly property string fontMain: "SF Pro Rounded"
    readonly property string fontIcon: "JetBrainsMono Nerd Font"

    // Geometry radii
    readonly property int radiusSmall:  8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge:  24
    readonly property int radiusPill:   999
}
