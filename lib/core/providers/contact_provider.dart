import 'package:flutter/foundation.dart';
      import 'dart:async';
      import '../data/services/contact_service.dart';
      import '../data/models/contact_model.dart';

      class ContactProvider extends ChangeNotifier {
        final ContactService _contactService = ContactService();

        List<ContactModel> _allContacts = [];
        List<ContactModel> _deviceContacts = [];
        List<ContactModel> _appUsers = [];
        List<ContactModel> _filteredContacts = [];

        bool _isLoading = false;
        bool _isSearching = false;
        bool _hasPermission = false;
        bool _isInitialized = false;
        String? _error;
        String _searchQuery = '';
        ContactsView _currentView = ContactsView.all;

        Timer? _searchDebouncer;

        List<ContactModel> get allContacts => List.unmodifiable(_allContacts);
        List<ContactModel> get deviceContacts => List.unmodifiable(_deviceContacts);
        List<ContactModel> get appUsers => List.unmodifiable(_appUsers);
        List<ContactModel> get displayedContacts => List.unmodifiable(_filteredContacts);
        bool get isLoading => _isLoading;
        bool get isSearching => _isSearching;
        bool get hasPermission => _hasPermission;
        bool get isInitialized => _isInitialized;
        String? get error => _error;
        String get searchQuery => _searchQuery;
        ContactsView get currentView => _currentView;
        int get appUsersCount => _appUsers.length;
        int get deviceContactsCount => _deviceContacts.length;
        int get totalContactsCount => _allContacts.length;

        Map<String, List<ContactModel>> get groupedContacts {
          final grouped = <String, List<ContactModel>>{};
          for (final contact in _filteredContacts) {
            final firstLetter = contact.displayName.isNotEmpty
                ? contact.displayName[0].toUpperCase()
                : '#';
            if (!grouped.containsKey(firstLetter)) {
              grouped[firstLetter] = [];
            }
            grouped[firstLetter]!.add(contact);
          }
          return grouped;
        }

        ContactProvider() {
          _initialize();
        }

        Future<void> _initialize() async {
          try {
            print('🔥 ContactProvider: Initializing...');
            await _checkPermission();
            if (_hasPermission) {
              await refreshContacts();
            }
            _isInitialized = true;
            print('✅ ContactProvider: Initialized successfully');
            notifyListeners();
          } catch (e) {
            print('❌ ContactProvider: Initialization failed - $e');
            _setError('Failed to initialize contacts');
            _isInitialized = true;
            notifyListeners();
          }
        }

        Future<void> _checkPermission() async {
          try {
            _hasPermission = await _contactService.hasContactsPermission();
            print('🔐 ContactProvider: Has permission = $_hasPermission');
          } catch (e) {
            print('❌ ContactProvider: Error checking permission - $e');
            _hasPermission = false;
          }
        }

        Future<bool> requestPermission() async {
          try {
            _setLoading(true);
            clearError();
            print('🔐 ContactProvider: Requesting permission');
            final result = await _contactService.requestContactsPermission();
            if (result.isSuccess) {
              _hasPermission = true;
              await refreshContacts();
              return true;
            } else {
              _setError(result.error!);
              return false;
            }
          } catch (e) {
            print('❌ ContactProvider: Error requesting permission - $e');
            _setError('Failed to request permission');
            return false;
          }
        }

        Future<void> openAppSettings() async {
          try {
            await _contactService.openAppSettings();
          } catch (e) {
            print('❌ ContactProvider: Error opening settings - $e');
          }
        }

        Future<void> refreshContacts() async {
          try {
            _setLoading(true);
            clearError();
            print('🔄 ContactProvider: Refreshing contacts');
            if (!_hasPermission) {
              _setError('Contacts permission required');
              return;
            }
            final result = await _contactService.getCombinedContacts();
            if (result.isSuccess) {
              final contacts = result.data as List<ContactModel>;
              _allContacts = contacts;
              _deviceContacts = contacts.where((c) => c.isDeviceContact).toList();
              _appUsers = contacts.where((c) => c.isAppUser).toList();
              _applyCurrentFilter();
              print('✅ ContactProvider: Loaded ${contacts.length} contacts');
            } else {
              _setError(result.error!);
            }
          } catch (e) {
            print('❌ ContactProvider: Error refreshing contacts - $e');
            _setError('Failed to load contacts');
          } finally {
            _setLoading(false);
          }
        }

        Future<void> loadDeviceContacts() async {
          try {
            _setLoading(true);
            clearError();
            if (!_hasPermission) {
              _setError('Contacts permission required');
              return;
            }
            final result = await _contactService.getDeviceContacts();
            if (result.isSuccess) {
              _deviceContacts = result.data as List<ContactModel>;
              if (_currentView == ContactsView.device) {
                _applyCurrentFilter();
              }
              print('✅ ContactProvider: Loaded ${_deviceContacts.length} device contacts');
            } else {
              _setError(result.error!);
            }
          } catch (e) {
            print('❌ ContactProvider: Error loading device contacts - $e');
            _setError('Failed to load device contacts');
          } finally {
            _setLoading(false);
          }
        }

        Future<void> loadAppUsers() async {
          try {
            _setLoading(true);
            clearError();
            final result = await _contactService.getAllAppUsers();
            if (result.isSuccess) {
              _appUsers = result.data as List<ContactModel>;
              if (_currentView == ContactsView.appUsers) {
                _applyCurrentFilter();
              }
              print('✅ ContactProvider: Loaded ${_appUsers.length} app users');
            } else {
              _setError(result.error!);
            }
          } catch (e) {
            print('❌ ContactProvider: Error loading app users - $e');
            _setError('Failed to load app users');
          } finally {
            _setLoading(false);
          }
        }

        void searchContacts(String query) {
          _searchQuery = query;
          _searchDebouncer?.cancel();
          if (query.isEmpty) {
            _isSearching = false;
            _applyCurrentFilter();
            notifyListeners();
            return;
          }
          _isSearching = true;
          notifyListeners();
          _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
            _performSearch(query);
          });
        }

        void _performSearch(String query) {
          try {
            final lowercaseQuery = query.toLowerCase();
            List<ContactModel> sourceContacts;
            switch (_currentView) {
              case ContactsView.all:
                sourceContacts = _allContacts;
                break;
              case ContactsView.device:
                sourceContacts = _deviceContacts;
                break;
              case ContactsView.appUsers:
                sourceContacts = _appUsers;
                break;
            }
            _filteredContacts = sourceContacts.where((contact) {
              if (contact.displayName.toLowerCase().contains(lowercaseQuery)) {
                return true;
              }
              if (contact.phoneNumbers.any((phone) =>
                  phone.replaceAll(RegExp(r'[^\d]'), '').contains(lowercaseQuery))) {
                return true;
              }
              if (contact.emails.any((email) =>
                  email.toLowerCase().contains(lowercaseQuery))) {
                return true;
              }
              if (contact.status != null &&
                  contact.status!.toLowerCase().contains(lowercaseQuery)) {
                return true;
              }
              return false;
            }).toList();
            _isSearching = false;
            print('🔍 ContactProvider: Search for "$query" found ${_filteredContacts.length} results');
            notifyListeners();
          } catch (e) {
            print('❌ ContactProvider: Error searching contacts - $e');
            _isSearching = false;
            _setError('Search failed');
          }
        }

        void clearSearch() {
          _searchQuery = '';
          _isSearching = false;
          _searchDebouncer?.cancel();
          _applyCurrentFilter();
        }

        void setContactsView(ContactsView view) {
          if (_currentView == view) return;
          _currentView = view;
          _applyCurrentFilter();
          print('👁️ ContactProvider: Changed view to $view');
        }

        void _applyCurrentFilter() {
          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
            return;
          }
          switch (_currentView) {
            case ContactsView.all:
              _filteredContacts = List.from(_allContacts);
              break;
            case ContactsView.device:
              _filteredContacts = List.from(_deviceContacts);
              break;
            case ContactsView.appUsers:
              _filteredContacts = List.from(_appUsers);
              break;
          }
          notifyListeners();
        }

        ContactModel? getContactById(String id) {
          try {
            return _allContacts.firstWhere((contact) => contact.id == id);
          } catch (e) {
            return null;
          }
        }

        Future<ContactModel?> getContactByUserId(String userId) async {
          try {
            final existingContact = _allContacts
                .where((c) => c.userId == userId)
                .firstOrNull;
            if (existingContact != null) {
              return existingContact;
            }
            final result = await _contactService.getContactByUserId(userId);
            if (result.isSuccess) {
              return result.data as ContactModel;
            }
            return null;
          } catch (e) {
            print('❌ ContactProvider: Error getting contact by user ID - $e');
            return null;
          }
        }

        Future<bool> updateUserProfile({
          String? phoneNumber,
          String? displayName,
          String? status,
        }) async {
          try {
            _setLoading(true);
            clearError();
            final result = await _contactService.updateUserProfile(
              phoneNumber: phoneNumber,
              displayName: displayName,
              status: status,
            );
            if (result.isSuccess) {
              await refreshContacts();
              return true;
            } else {
              _setError(result.error!);
              return false;
            }
          } catch (e) {
            print('❌ ContactProvider: Error updating profile - $e');
            _setError('Failed to update profile');
            return false;
          }
        }

        void _setLoading(bool loading) {
          _isLoading = loading;
          notifyListeners();
        }

        void _setError(String error) {
          _error = error;
          _isLoading = false;
          _isSearching = false;
          notifyListeners();
        }

        void clearError() {
          _error = null;
          notifyListeners();
        }

        Map<String, dynamic> getContactsState() {
          return {
            'totalContacts': totalContactsCount,
            'deviceContacts': deviceContactsCount,
            'appUsers': appUsersCount,
            'hasPermission': hasPermission,
            'isInitialized': isInitialized,
            'isLoading': isLoading,
            'currentView': currentView.toString(),
            'searchQuery': searchQuery,
            'error': error,
          };
        }

        Future<void> refreshPermissionStatus() async {
          await _checkPermission();
          notifyListeners();
        }

        @override
        void dispose() {
          print('🗑️ ContactProvider: Disposing...');
          _searchDebouncer?.cancel();
          super.dispose();
        }
      }

      enum ContactsView {
        all,
        device,
        appUsers,
      }

      extension ContactsViewExtension on ContactsView {
        String get displayName {
          switch (this) {
            case ContactsView.all:
              return 'All Contacts';
            case ContactsView.device:
              return 'Device Contacts';
            case ContactsView.appUsers:
              return 'App Users';
          }
        }

        String get description {
          switch (this) {
            case ContactsView.all:
              return 'Device contacts and app users';
            case ContactsView.device:
              return 'Contacts from your device';
            case ContactsView.appUsers:
              return 'Users registered on the app';
          }
        }
      }