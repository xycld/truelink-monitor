#include "wifimonitor.h"

#include <QQmlEngine>
#include <QQmlExtensionPlugin>

class TrueLinkPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override {
        if (QLatin1String(uri) != QLatin1String("org.kde.plasma.private.truelinkmonitor")) {
            return;
        }
        
        qmlRegisterSingletonType<WifiMonitor>(uri, 1, 0, "WifiMonitor",
            [](QQmlEngine *engine, QJSEngine *) -> QObject * {
                auto *monitor = new WifiMonitor;
                engine->setObjectOwnership(monitor, QQmlEngine::CppOwnership);
                return monitor;
            });
    }
};

#include "truelinkplugin.moc"
