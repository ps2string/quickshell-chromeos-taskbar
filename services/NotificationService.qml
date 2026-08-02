pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

NotificationServer {
    id: server

    persistenceSupported: true
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: notif => {
        notif.tracked = true;
    }
}
