import Foundation

enum SessionStatus: String, Codable {
    case draft
    case open
    case locked
    case completed
    case canceled
}

enum ParticipantStatus: String, Codable {
    case joined
    case waitlist
    case withdrawn
    case lateWithdraw = "late_withdraw"
}

enum PaymentStatus: String, Codable {
    case unpaid
    case paid
    case waived
}

enum PaymentMethodType: String, Codable {
    case venmo
    case zelle
    case other
}

enum FeeMode: String, Codable {
    case fixedPerPerson = "fixed_per_person"
    case splitByAttendance = "split_by_attendance"
}

struct User: Codable, Identifiable {
    let id: String
    let nickname: String
    let avatarURL: String?
    let wechatOpenID: String?
    let wechatUnionID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarURL = "avatar_url"
        case wechatOpenID = "wechat_openid"
        case wechatUnionID = "wechat_unionid"
    }
}

struct FeeRule: Codable {
    let mode: FeeMode
    let amount: Double?
    let lateWithdrawRatio: Double?

    enum CodingKeys: String, CodingKey {
        case mode
        case amount
        case lateWithdrawRatio = "late_withdraw_ratio"
    }
}

struct Session: Codable, Identifiable {
    let id: String
    let title: String
    let startsAt: Date
    let endsAt: Date?
    let location: String
    let courtCount: Int
    let maxParticipants: Int
    let withdrawDeadline: Date
    let finalizeAt: Date?
    let status: SessionStatus
    let feeRule: FeeRule
    let initiatorUser: User
    let adminUserIDs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case location
        case courtCount = "court_count"
        case maxParticipants = "max_participants"
        case withdrawDeadline = "withdraw_deadline"
        case finalizeAt = "finalize_at"
        case status
        case feeRule = "fee_rule"
        case initiatorUser = "initiator_user"
        case adminUserIDs = "admin_user_ids"
    }
}

struct SessionListResponse: Codable {
    let items: [Session]
}

struct SessionDetail: Codable {
    let id: String
    let title: String
    let startsAt: Date
    let endsAt: Date?
    let location: String
    let courtCount: Int
    let maxParticipants: Int
    let withdrawDeadline: Date
    let finalizeAt: Date?
    let status: SessionStatus
    let feeRule: FeeRule
    let initiatorUser: User
    let admins: [SessionAdmin]
    let participants: [SessionParticipant]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case location
        case courtCount = "court_count"
        case maxParticipants = "max_participants"
        case withdrawDeadline = "withdraw_deadline"
        case finalizeAt = "finalize_at"
        case status
        case feeRule = "fee_rule"
        case initiatorUser = "initiator_user"
        case admins
        case participants
    }
}

struct SessionAdmin: Codable, Identifiable {
    let id: String
    let userID: String
    let nickname: String
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case nickname
        case addedAt = "added_at"
    }
}

struct SessionAdminsResponse: Codable {
    let items: [SessionAdmin]
}

struct SessionParticipant: Codable, Identifiable {
    let id: String
    let sessionID: String
    let user: User
    let queuePosition: Int
    let status: ParticipantStatus
    let joinedAt: Date
    let withdrewAt: Date?
    let isReplacement: Bool
    let replacedParticipantID: String?
    let stayedLate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case user
        case queuePosition = "queue_position"
        case status
        case joinedAt = "joined_at"
        case withdrewAt = "withdrew_at"
        case isReplacement = "is_replacement"
        case replacedParticipantID = "replaced_participant_id"
        case stayedLate = "stayed_late"
    }
}

enum WithdrawReason: String, Codable {
    case beforeDeadline = "before_deadline"
    case lateNoReplacement = "late_no_replacement"
    case lateReplacedBeforeFinalize = "late_replaced_before_finalize"
}

struct WithdrawResult: Codable {
    let participantID: String
    let status: ParticipantStatus
    let liableForBaseFee: Bool
    let reason: WithdrawReason

    enum CodingKeys: String, CodingKey {
        case participantID = "participant_id"
        case status
        case liableForBaseFee = "liable_for_base_fee"
        case reason
    }
}

struct PaymentMethod: Codable, Identifiable {
    let id: String
    let sessionID: String
    let ownerUserID: String
    let type: PaymentMethodType
    let label: String
    let accountRef: String
    let deepLink: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case ownerUserID = "owner_user_id"
        case type
        case label
        case accountRef = "account_ref"
        case deepLink = "deep_link"
    }
}

struct PaymentMethodsResponse: Codable {
    let items: [PaymentMethod]
}

struct PaymentRecord: Codable, Identifiable {
    let id: String
    let sessionID: String
    let participantID: String
    let baseFeeAmount: Double
    let lateUsageFeeAmount: Double
    let totalAmount: Double
    let status: PaymentStatus
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case participantID = "participant_id"
        case baseFeeAmount = "base_fee_amount"
        case lateUsageFeeAmount = "late_usage_fee_amount"
        case totalAmount = "total_amount"
        case status
        case updatedAt = "updated_at"
    }
}

struct PaymentRecordsResponse: Codable {
    let items: [PaymentRecord]
}

struct WeChatLoginRequest: Codable {
    let code: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct CreateSessionRequest: Codable {
    let title: String
    let startsAt: Date
    let endsAt: Date?
    let location: String
    let courtCount: Int
    let maxParticipants: Int
    let withdrawDeadline: Date
    let feeRule: FeeRule

    enum CodingKeys: String, CodingKey {
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case location
        case courtCount = "court_count"
        case maxParticipants = "max_participants"
        case withdrawDeadline = "withdraw_deadline"
        case feeRule = "fee_rule"
    }
}

struct UpdateParticipantRequest: Codable {
    let stayedLate: Bool?
    let adminNote: String?

    enum CodingKeys: String, CodingKey {
        case stayedLate = "stayed_late"
        case adminNote = "admin_note"
    }
}

struct AddSessionAdminRequest: Codable {
    let userID: String
    let nickname: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nickname
    }
}

struct CreatePaymentMethodRequest: Codable {
    let type: PaymentMethodType
    let label: String
    let accountRef: String
    let deepLink: String?

    enum CodingKeys: String, CodingKey {
        case type
        case label
        case accountRef = "account_ref"
        case deepLink = "deep_link"
    }
}

struct UpsertPaymentRecordRequest: Codable {
    let participantID: String
    let baseFeeAmount: Double
    let lateUsageFeeAmount: Double?
    let status: PaymentStatus
    let note: String?

    enum CodingKeys: String, CodingKey {
        case participantID = "participant_id"
        case baseFeeAmount = "base_fee_amount"
        case lateUsageFeeAmount = "late_usage_fee_amount"
        case status
        case note
    }
}
