import IMAIKit
import UIKit

/// 按 USAGE 走通本地能力：Opus 编码器、会话记录写入 / 读取、AI 偏好。不需要连服务端。
final class ViewController: UITableViewController {

    private enum Row: Int, CaseIterable {
        case opus, appendMessage, conversations, model
    }

    private var observer: NSObjectProtocol?

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "IMAIKit"
        observer = NotificationCenter.default.addObserver(forName: .imaiConversationsDidChange,
                                                          object: nil, queue: .main) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        switch Row(rawValue: indexPath.row)! {
        case .opus:
            cell.textLabel?.text = "Opus 编码器（libopus）"
            cell.detailTextLabel?.text = Self.opusStatus()
        case .appendMessage:
            cell.textLabel?.text = "写入今天的一条对话"
            cell.accessoryType = .disclosureIndicator
        case .conversations:
            let all = IMAIKit.shared.conversationStore.conversations()
            cell.textLabel?.text = "会话 / 消息"
            cell.detailTextLabel?.text = "\(all.count) / \(all.reduce(0) { $0 + $1.messages.count })"
        case .model:
            cell.textLabel?.text = "AI 模型偏好（点按切换）"
            cell.detailTextLabel?.text = "\(IMAIKit.shared.preferences.model)"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Row(rawValue: indexPath.row)! {
        case .appendMessage:
            let store = IMAIKit.shared.conversationStore
            let conversation = store.dailyConversation(model: .chat,
                                                       fallbackTitle: IMAIDailyConversationTitle.today())
            store.append(message: IMAIMessage(role: .user, text: "你好"), to: conversation.id)
            store.append(message: IMAIMessage(role: .assistant, text: "你好，我是 Example。"), to: conversation.id)
        case .model:
            let all: [IMAIModel] = [.chat, .pet, .translate]
            let next = all[((all.firstIndex(of: IMAIKit.shared.preferences.model) ?? 0) + 1) % all.count]
            IMAIKit.shared.preferences.model = next
            tableView.reloadRows(at: [indexPath], with: .automatic)
        default:
            break
        }
    }

    private static func opusStatus() -> String {
        do {
            let encoder = try IMAIOpusEncoder()
            let packet = try encoder.encode([Int16](repeating: 0, count: 320))
            return "可用（20 ms 静音 → \(packet.count) B）"
        } catch {
            return "不可用：\(error)"
        }
    }
}
