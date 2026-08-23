# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

#####################################################################
## Internal Application:
#####################################################################

qt_internal_add_app(rasterwindow
    SOURCES
        main.cpp
        rasterwindow.cpp rasterwindow.h
    LIBRARIES
        Qt::Core
        Qt::CorePrivate
        Qt::Gui
        Qt::GuiPrivate
        Qt::TextRendererPrivate
)

set_target_properties(rasterwindow PROPERTIES WIN32_EXECUTABLE FALSE)
