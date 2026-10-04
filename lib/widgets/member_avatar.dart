import 'package:flutter/material.dart';
import '../models/team_member.dart';

class MemberAvatar extends StatelessWidget {
  final TeamMember? member;
  final double radius;
  const MemberAvatar(this.member, {super.key, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(member?.colorValue ?? 0xFF9CA3AF),
      child: Text(member?.initials ?? '?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.75)),
    );
  }
}
