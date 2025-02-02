// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QCommandLineParser>
#include <QLibraryInfo>
#include <QCoreApplication>

#include <QtTextRenderer/qttextrendererversion.h>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName(u"Qt Text to Image"_s);
    QCoreApplication::setOrganizationName(u"QtProject"_s);
    QCoreApplication::setOrganizationDomain(u"qt-project.org"_s);
    QCoreApplication::setApplicationVersion(QString::fromLatin1(QTTEXTRENDERER_VERSION_STR));

    QCoreApplication app(argc, argv);

    QCommandLineParser parser;
    parser.addOptions({
            { "port", QCoreApplication::translate("main", "The port the server listens on."),
              "port" },
    });
    parser.addHelpOption();
    parser.process(app);

    return app.exec();
}
