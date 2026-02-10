#include "app/TweakListModel.h"

TweakListModel::TweakListModel(QList<Tweak> &tweaks, QObject *parent)
    : QAbstractListModel(parent), m_tweaks(tweaks)
{
}

int TweakListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_tweaks.size();
}

QVariant TweakListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tweaks.size())
        return {};

    const Tweak &t = m_tweaks.at(index.row());
    switch (role) {
    case IdRole:            return t.id;
    case NameRole:          return t.name;
    case DescriptionRole:   return t.description;
    case CategoryRole:      return t.category;
    case RecommendedRole:   return t.recommended;
    case AppliedRole:       return t.applied;
    case RequiresAdminRole: return t.requiresAdmin;
    case RiskRole:          return t.risk;
    case LearnMoreRole:     return t.learnMore;
    default: return {};
    }
}

QHash<int, QByteArray> TweakListModel::roleNames() const
{
    return {
        {IdRole,            "tweakId"},
        {NameRole,          "name"},
        {DescriptionRole,   "description"},
        {CategoryRole,      "category"},
        {RecommendedRole,   "recommended"},
        {AppliedRole,       "applied"},
        {RequiresAdminRole, "requiresAdmin"},
        {RiskRole,          "risk"},
        {LearnMoreRole,     "learnMore"}
    };
}

bool TweakListModel::isValidRow(int row) const
{
    return row >= 0 && row < m_tweaks.size();
}

QString TweakListModel::tweakIdForRow(int row) const
{
    return isValidRow(row) ? m_tweaks.at(row).id : QString();
}

void TweakListModel::refresh()
{
    if (!m_tweaks.isEmpty())
        emit dataChanged(index(0), index(m_tweaks.size() - 1));
}

void TweakListModel::refreshRow(int row)
{
    if (isValidRow(row))
        emit dataChanged(index(row), index(row));
}
