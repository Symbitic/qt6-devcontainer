// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#ifndef QTEXTRENDERER_P_H
#define QTEXTRENDERER_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtCore/qobject.h>
#include <QtCore/qstring.h>
#include <QtTextRenderer/qttextrendererglobal.h>

QT_BEGIN_NAMESPACE

class Q_TEXTRENDERER_EXPORT QTextRenderer : public QObject
{
    Q_OBJECT
public:
    QTextRenderer(QObject *parent = nullptr);

    QString text() const;
    void setText(const QString &text);

Q_SIGNALS:
    void textChanged(const QString &text);

private:
    QString m_text;
};

QT_END_NAMESPACE

#endif // QTEXTRENDERER_P_H