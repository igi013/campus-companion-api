//
//  AnnouncementsViewController.swift
//  CampusCompanion
//
//  Created by John Ronen Soriano on 9/24/26.
//

import UIKit
import CoreData

private enum RemoteEndpoint {
    static let announcements = URL(
        string: "https://raw.githubusercontent.com/igi013/" +
        "campus-companion-api/main/announcements.json"
    )!
}

class AnnouncementsViewController: UITableViewController {

    private var announcements: [CampusAnnouncement] = []
    private var selectedAnnouncement: CampusAnnouncement?
    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Campus Announcements"
        seedInitialAnnouncementsIfNeeded()
        loadAnnouncements()
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "AnnouncementCell",
            for: indexPath
        ) as? AnnouncementCell else {
            return UITableViewCell()
        }

        cell.configure(with: announcements[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAnnouncement = announcements[indexPath.row]
        performSegue(withIdentifier: "ShowAnnouncementDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowAnnouncementDetailSegue",
              let destination = segue.destination as? DetailViewController,
              let announcement = selectedAnnouncement else {
            return
        }

        destination.announcement = announcement
    }

    @IBAction func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "New Announcement",
            message: "Enter a title and category.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Title"
        }

        alert.addTextField { textField in
            textField.placeholder = "Category"
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let titleText = alert?.textFields?[0].text, !titleText.isEmpty,
                  let categoryText = alert?.textFields?[1].text, !categoryText.isEmpty else {
                return
            }

            let newAnnouncement = CampusAnnouncement(context: self.context)
            newAnnouncement.title = titleText
            newAnnouncement.date = DateFormatter.localizedString(
                from: Date(),
                dateStyle: .long,
                timeStyle: .none
            )
            newAnnouncement.category = categoryText
            newAnnouncement.location = "Campus"
            newAnnouncement.priorityLevel = "Normal"

            try? self.context.save()
            self.loadAnnouncements()
        }

        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func refreshTapped(_ sender: UIBarButtonItem) {
        fetchAnnouncementsFromServer()
    }

    func fetchAnnouncementsFromServer() {
        let task = URLSession.shared.dataTask(
            with: RemoteEndpoint.announcements
        ) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected server response.")
                return
            }

            guard let data = data else { return }

            print("Reached network handler with \(data.count) bytes.")
            if let rawJSON = String(data: data, encoding: .utf8) {
                print(rawJSON)
            }

            do {
                let decoder = JSONDecoder()
                let decodedAnnouncements = try decoder.decode([AnnouncementDTO].self, from: data)

                DispatchQueue.main.async {
                    self.replaceAnnouncements(with: decodedAnnouncements)
                    self.showNetworkConfirmationAlert(byteCount: data.count)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }

        task.resume()
    }

    func replaceAnnouncements(with dtos: [AnnouncementDTO]) {
        let deleteRequest: NSFetchRequest<CampusAnnouncement> =
        CampusAnnouncement.fetchRequest()
        let existing = (try? context.fetch(deleteRequest)) ?? []

        for item in existing {
            context.delete(item)
        }

        for dto in dtos {
            let announcement = CampusAnnouncement(context: context)
            announcement.title = dto.title
            announcement.date = dto.date
            announcement.category = dto.category
            announcement.location = dto.location
            announcement.priorityLevel = dto.priorityLevel
        }

        try? context.save()
        loadAnnouncements()
        tableView.reloadData()
    }

    func showNetworkConfirmationAlert(byteCount: Int) {
        let alert = UIAlertController(
            title: "Server Reached",
            message: "Received \(byteCount) bytes from the " +
            "announcements endpoint.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let announcement = announcements[indexPath.row]
            context.delete(announcement)
            try? context.save()
            announcements.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    private func seedInitialAnnouncementsIfNeeded() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        let existingCount = (try? context.count(for: request)) ?? 0
        guard existingCount == 0 else { return }

        let seedAnnouncements = [
            ("Enrollment Period Extended", "August 3, 2026", "Registrar", "Registrar Office", "High"),
            ("Library Orientation Schedule", "August 5, 2026", "Library", "Main Library", "Normal"),
            ("Campus Wi-Fi Maintenance", "August 8, 2026", "IT Services", "All Buildings", "High"),
            ("Student Organization Fair", "August 12, 2026", "Student Affairs", "Activity Center", "Normal"),
            ("Scholarship Application Deadline", "August 15, 2026", "Scholarships", "Admissions Office", "High"),
            ("Intramurals Tryouts", "August 18, 2026", "Sports", "Gymnasium", "Normal")
        ]

        for seed in seedAnnouncements {
            let announcement = CampusAnnouncement(context: context)
            announcement.title = seed.0
            announcement.date = seed.1
            announcement.category = seed.2
            announcement.location = seed.3
            announcement.priorityLevel = seed.4
        }

        try? context.save()
    }

    private func loadAnnouncements() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        announcements = (try? context.fetch(request)) ?? []
        tableView.reloadData()
    }
}
