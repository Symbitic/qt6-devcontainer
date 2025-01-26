// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#include "qtextrenderer_p.h"

#include <QtCore/QtGlobal>

QT_BEGIN_NAMESPACE

QTextRenderer::QTextRenderer(QObject *parent)
    : QObject(parent)
{
}

QString QTextRenderer::text() const
{
    return m_text;
}

void QTextRenderer::setText(const QString &text)
{
    if (m_text != text) {
        m_text = text;
        emit textChanged(text);
    }
}

QT_END_NAMESPACE