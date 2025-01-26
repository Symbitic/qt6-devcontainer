# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

#####################################################################
## Internal Library:
#####################################################################

qt_internal_add_module(TextRendererPrivate
    INTERNAL_MODULE
    STATIC
    SOURCES
        qttextrendererglobal.h
        qtextrenderer_p.h qtextrenderer.cpp
    DEFINES
        QT_BUILD_TEXTRENDERER_LIB
        QT_NO_CONTEXTLESS_CONNECT
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Gui
)