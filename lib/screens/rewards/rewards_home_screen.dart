import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../globals.dart';
import 'rewards_storage.dart';

class RewardsHomePage extends StatefulWidget {
  const RewardsHomePage({super.key, this.city = 'Athens'});

  final String city;

  @override
  State<RewardsHomePage> createState() => _RewardsHomePageState();
}

class _RewardsHomePageState extends State<RewardsHomePage> with RouteAware {
  bool _loading = true;
  List<String> _displayList = [];
  StreamSubscription? _sub;
  String? _usernameCache;

 
  String? _bonusCode;
  bool _checkingBonus = true;

  @override
  void initState() {
    super.initState();
    _initListenerAndLoad();
  }

  Future<void> _initListenerAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _usernameCache = prefs.getString('current_user');

    _sub = RewardsStorage.changes.listen((evt) {
      final u = _usernameCache;
      if (u == null) return;

      if (evt.username == u.trim() && evt.city == widget.city.trim()) {
        _loadState(syncCloud: false);
      }
    });

    _loadState(syncCloud: true);
  }

  @override
  void didUpdateWidget(covariant RewardsHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _loadState(syncCloud: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadState(syncCloud: true);
  }

  @override
  void didPush() {
    _loadState(syncCloud: true);
  }

  Future<void> _loadState({bool syncCloud = false}) async {
    if (!mounted) return;
    if (_displayList.isEmpty) setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('current_user');
    _usernameCache = username;

    if (username == null) {
      final tempList = <String>[];
      while (tempList.length < 5) {
        tempList.add('Reward Locked');
      }
      if (!mounted) return;
      setState(() {
        _displayList = tempList;
        _loading = false;
        _bonusCode = null;
      });
      return;
    }

    if (syncCloud) {
      await RewardsStorage.syncWithCloud(widget.city, username);
    }

    await RewardsStorage.syncDeletedCoupons(widget.city, username);

    final unlockedRaw = await RewardsStorage.loadUnlockedCoupons(widget.city, username);
    final tempList = unlockedRaw.map(RewardsStorage.extractCode).toList();

    while (tempList.length < 5) {
      tempList.add('Reward Locked');
    }

    
    await _checkBonusStatus(username, unlockedRaw);

    if (!mounted) return;
    setState(() {
      _displayList = tempList;
      _loading = false;
    });
  }


  Future<void> _checkBonusStatus(String username, Set<String> currentUnlockedRaw) async {
    if (!mounted) return;
    setState(() => _checkingBonus = true);

    try {
      final userDocRef = FirebaseFirestore.instance.collection('travellers').doc(username);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        if (mounted) setState(() => _checkingBonus = false);
        return;
      }

      final data = userDoc.data()!;
      final Map<String, dynamic> bonusMap = data['bonus_rewards'] ?? {};

     
      if (bonusMap.containsKey(widget.city)) {
        final val = bonusMap[widget.city] as String;
        if (mounted) {
          setState(() {
            _bonusCode = val.split('||')[0];
            _checkingBonus = false;
          });
        }
        return;
      }

      
      List<dynamic> unlockedAttractions = data['unlocked_attractions'] ?? [];
      final cityUnlocks = unlockedAttractions.where((u) => u.toString().startsWith("${widget.city}_")).toList();
      
      const int totalMissions = 6; 

      if (cityUnlocks.length >= totalMissions) {
        await _unlockNewBonusCoupon(username, currentUnlockedRaw);
      } else {
        if (mounted) {
          setState(() {
            _bonusCode = null;
            _checkingBonus = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _checkingBonus = false);
    }
  }

  Future<void> _unlockNewBonusCoupon(String username, Set<String> existingRaw) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('city_coupons')
          .where('city', isEqualTo: widget.city)
          .where('isRedeemed', isEqualTo: false)
          .get();

      final existingCodes = existingRaw.map(RewardsStorage.extractCode).toSet();
      final availableDocs = snapshot.docs.where((d) {
        final code = d.data()['code']?.toString() ?? '';
        return code.isNotEmpty && !existingCodes.contains(code);
      }).toList();

      if (availableDocs.isNotEmpty) {
        final random = Random();
        final picked = availableDocs[random.nextInt(availableDocs.length)];
        final newCode = picked.data()['code'];
        final partner = picked.data()['partner'] ?? 'Partner';
        final valToSave = "$newCode||$partner";

        
        await FirebaseFirestore.instance.collection('travellers').doc(username).set({
          'bonus_rewards': { widget.city: valToSave }
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _bonusCode = newCode;
            _checkingBonus = false;
          });
        }
      } else {
        if (mounted) setState(() => _checkingBonus = false);
      }
    } catch (e) {
      if (mounted) setState(() => _checkingBonus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEBF4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Text(
                    "Rewards",
                    style: TextStyle(
                      color: Color(0xFF0D2C54),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      fontFamily: 'serif',
                    ),
                  ),
                  Text(
                    widget.city,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'serif',
                      color: Color(0xFF3E4C63),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                itemCount: _displayList.length,
                itemBuilder: (context, index) {
                  final itemText = _displayList[index];
                  final isLocked = itemText == 'Reward Locked';
                  final displayText = isLocked ? "Locked Reward" : itemText;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Icon(
                          isLocked ? Icons.lock : Icons.check_circle,
                          color: Colors.black54,
                          size: 24,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            height: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.grey[400] : const Color(0xFF9E8484),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
           
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Column(
                children: [
                  const Text(
                    "Hmm...Complete the set – unlock the bonus",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'serif',
                      color: Color(0xFF0D2C54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        _bonusCode == null ? Icons.lock : Icons.stars,
                        color: Colors.black54,
                        size: 24,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _bonusCode == null ? Colors.grey[400] : const Color(0xFF9E8484),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: _checkingBonus 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                _bonusCode ?? "Bonus Reward Locked",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}