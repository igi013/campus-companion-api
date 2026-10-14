//
//  AnnouncementCell.swift
//  CampusCompanion
//
//  Created by John Ronen Soriano on 9/24/26.
//

import UIKit

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var categoryIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    func configure(with announcement: CampusAnnouncement) {
        titleLabel.text = announcement.title
        dateLabel.numberOfLines = 2
        dateLabel.text = """
        \(announcement.category) - \(announcement.date)
        \(announcement.location) - \(announcement.priorityLevel)
        """
        categoryIconImageView.image = UIImage(systemName: "megaphone.fill")
        categoryIconImageView.tintColor = .systemBlue
    }
}
