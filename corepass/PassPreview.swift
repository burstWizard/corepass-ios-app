//
//  PassPreview.swift
//  corepass
//
//  Created by Hari Shankar on 9/4/25.
//

import SwiftUI

enum ApprovalStatus: String, CaseIterable, Codable {
    case pending, approved, rejected

    var display: String {
        switch self {
        case .pending:  "Pending"
        case .approved: "Approved"
        case .rejected: "Rejected"
        }
    }

    var tint: Color {
        switch self {
        case .pending:  .orange        // or .yellow; orange reads better in Dark Mode
        case .approved: .green
        case .rejected: .red
        }
    }
}

struct StatusPill: View {
    let status: ApprovalStatus
    var body: some View {
        Text(status.display)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .foregroundStyle(status.tint)
            .background(
                Capsule().fill(status.tint.opacity(0.15))
            )
    }
}



struct PassPreview: View {
    let from : String
    let to : String
    let startAt : Date
    let durationMinutes : Int
    let approval : ApprovalStatus
    let hairline = 1 / UIScreen.main.scale
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(from)
                    .font(.subheadline)
                    .lineLimit(1)
                Image(systemName:"arrow.right")
                    .font(.caption2)
                    .lineLimit(1)
                Text(to)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                StatusPill(status: approval)
                
            }
            HStack(spacing : 12) {
                Text("\(startAt.formatted(date : .abbreviated, time: .shortened)) | \(durationMinutes.formatted()) minutes")
                    .font(.caption)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(.systemGray4), lineWidth: 2)
        )
        .compositingGroup() // isolates before shadow so edges stay crisp

    }
}

#Preview {
    PassPreview(from : "C200", to : "C Boys Bathroom", startAt: .now, durationMinutes: 50, approval: .rejected)
}
