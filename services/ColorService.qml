import Quickshell
import Quickshell.Io
import QtQuick

pragma Singleton

Item {
    id: root

    property string themePath: Quickshell.env("HOME") + "/.config/quickshell/colors.json"

    FileView {
        path: root.themePath
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()

        JsonAdapter {
            id: jsonColors

            property string accent:        "#8ab4f8"
            property string accentDim:     "#283b5b"
            property string accentOnDim:   "#c0d8ff"
            property string bgBase:        "#1f1f23"
            property string bgSurface:     "#2b2d30"
            property string bgElevated:    "#3c4043"
            property string bgHover:       "#4a4e52"
            property string textPrimary:   "#e8eaed"
            property string textSecondary: "#9aa0a6"
            property string danger:        "#f28b82"
            property string success:       "#81c995"
            property string outline:       "#6b7280"
        }
    }

    readonly property color accent:        jsonColors.accent
    readonly property color accentDim:     jsonColors.accentDim
    readonly property color accentOnDim:   jsonColors.accentOnDim
    readonly property color bgBase:        jsonColors.bgBase
    readonly property color bgSurface:     jsonColors.bgSurface
    readonly property color bgElevated:    jsonColors.bgElevated
    readonly property color bgHover:       jsonColors.bgHover
    readonly property color textPrimary:   jsonColors.textPrimary
    readonly property color textSecondary: jsonColors.textSecondary
    readonly property color danger:        jsonColors.danger
    readonly property color success:       jsonColors.success
    readonly property color outline:       jsonColors.outline

    readonly property string fontMain: "SF Pro Rounded"
    readonly property string fontIcon: "JetBrainsMono Nerd Font"

    readonly property int radiusSmall:  8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge:  24
    readonly property int radiusPill:   999
}
