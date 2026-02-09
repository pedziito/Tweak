#pragma once

#include <QVariantList>

class StartupScanner
{
public:
    /// Scan Run keys & startup folders. Returns list of QVariantMap with
    /// keys: "name", "command", "source".
    QVariantList scan() const;
};
