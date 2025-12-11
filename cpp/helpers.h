#pragma once
#include <QGuiApplication>
#include <QFile>
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

inline ::rust::String readResourceFile(rust::Str resourcePath) {
    QString path = QString::fromUtf8(resourcePath.data(), resourcePath.size());
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        return std::string();
    }
    QByteArray data = f.readAll();
    auto s = std::string(data.constData(), data.size());
    return ::rust::String(s.c_str());
}

} // namespace VFileX
