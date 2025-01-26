# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

#####################################################################
## Internal Application:
#####################################################################

qt_internal_add_app(text2image
    SOURCES
        main.cpp
    LIBRARIES
        Qt::Core
        Qt::CorePrivate
        Qt::Gui
        Qt::GuiPrivate
        Qt::TextRendererPrivate
)

set_target_properties(text2image PROPERTIES WIN32_EXECUTABLE FALSE)
