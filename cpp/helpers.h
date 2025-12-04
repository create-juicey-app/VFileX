#pragma once
#include <QGuiApplication>
#include <QIcon>
#include <QString>
#include "rust/cxx.h"

namespace VFileX {

inline void setApplicationIcon(rust::Str resourcePath) {
    if (qApp) {
        QString path = QString::fromUtf8(resourcePath.data(), resourcePath.size());
        QIcon icon(path);
        qApp->setWindowIcon(icon);
    }
}

} // namespace VFileX
