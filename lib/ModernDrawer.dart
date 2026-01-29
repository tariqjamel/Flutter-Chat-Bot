import 'package:flutter/material.dart';
import 'styles.dart';
import 'HistoryManager.dart';
import 'HomePage.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ModernDrawer extends StatefulWidget {
  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 30,
        blur: 20,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: _buildHistoryList(),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppStyles.primaryColor, AppStyles.accentColor, Colors.white],
            ).createShader(bounds),
            child: Text("Gemini AI", 
              style: AppStyles.headingStyle.copyWith(
                fontSize: 26, 
                letterSpacing: 1.1,
                color: Colors.white,
              )
            ),
          ),
          const SizedBox(height: 4),
          Text("Advanced Assistant", 
            style: AppStyles.secondaryStyle.copyWith(
              color: AppStyles.primaryColor.withOpacity(0.8), 
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<ChatSession>>(
      future: HistoryManager.getAllSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, color: AppStyles.secondaryTextColor.withOpacity(0.5), size: 40),
                const SizedBox(height: 12),
                Text("No recent chats", style: AppStyles.secondaryStyle.copyWith(fontSize: 12)),
              ],
            ),
          );
        }

        final sessions = snapshot.data!;
        return ListView.builder(
          key: ValueKey(sessions.length),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 50,
                borderRadius: 12,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: AppStyles.primaryColor, size: 16),
                    ),
                    title: Text(
                      session.title,
                      style: AppStyles.bodyStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
                      onPressed: () async {
                        await HistoryManager.deleteSession(session.id);
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (c) => HomePage(session: session)),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          _buildDrawerItem(
            icon: Icons.add_circle_outline,
            label: "New Chat",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.delete_forever_outlined,
            label: "Clear History",
            onTap: () async {
              await HistoryManager.clearAllHistory();
              setState(() {});
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            label: "Settings",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white60, size: 18),
          title: Text(label, style: AppStyles.bodyStyle.copyWith(fontSize: 13)),
          onTap: onTap,
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
