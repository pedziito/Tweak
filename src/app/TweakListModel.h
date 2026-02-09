#pragma once

#include <QAbstractListModel>

#include "app/TweakEngine.h"

class TweakListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        CategoryRole,
        RecommendedRole,
        AppliedRole,
        RequiresAdminRole
    };

    explicit TweakListModel(QList<Tweak> &tweaks, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool isValidRow(int row) const;
    QString tweakIdForRow(int row) const;
    void refresh();
    void refreshRow(int row);

private:
    QList<Tweak> &m_tweaks;
};
