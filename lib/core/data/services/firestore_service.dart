// ============================================================================
// File: lib/core/data/services/firestore_service.dart
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore service for all database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // DOCUMENT OPERATIONS
  // ============================================================================

  /// Create or update a document
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(
        data,
        SetOptions(merge: merge),
      );
    } catch (e) {
      print('❌ FirestoreService: Set document failed - $e');
      rethrow;
    }
  }

  /// Get a single document
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ FirestoreService: Get document failed - $e');
      rethrow;
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('❌ FirestoreService: Update document failed - $e');
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('❌ FirestoreService: Delete document failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // COLLECTION OPERATIONS
  // ============================================================================

  /// Query documents with basic where clause
  Future<QuerySnapshot> queryDocuments({
    required String collection,
    String? field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Add where clauses
      if (field != null) {
        if (isEqualTo != null) {
          query = query.where(field, isEqualTo: isEqualTo);
        }
        if (isNotEqualTo != null) {
          query = query.where(field, isNotEqualTo: isNotEqualTo);
        }
        if (isLessThan != null) {
          query = query.where(field, isLessThan: isLessThan);
        }
        if (isLessThanOrEqualTo != null) {
          query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        }
        if (isGreaterThan != null) {
          query = query.where(field, isGreaterThan: isGreaterThan);
        }
        if (isGreaterThanOrEqualTo != null) {
          query = query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        }
        if (whereIn != null) {
          query = query.where(field, whereIn: whereIn);
        }
        if (whereNotIn != null) {
          query = query.where(field, whereNotIn: whereNotIn);
        }
        if (isNull != null) {
          query = query.where(field, isNull: isNull);
        }
      }

      // Add ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Add limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      print('❌ FirestoreService: Query documents failed - $e');
      rethrow;
    }
  }

  /// Get all documents in a collection
  Future<QuerySnapshot> getAllDocuments({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      print('❌ FirestoreService: Get all documents failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // SUBCOLLECTION OPERATIONS
  // ============================================================================

  /// Add document to subcollection
  Future<DocumentReference> addToSubcollection({
    required String collection,
    required String documentId,
    required String subcollection,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _firestore
          .collection(collection)
          .doc(documentId)
          .collection(subcollection)
          .add(data);
    } catch (e) {
      print('❌ FirestoreService: Add to subcollection failed - $e');
      rethrow;
    }
  }

  /// Get subcollection documents
  Future<QuerySnapshot> getSubcollection({
    required String collection,
    required String documentId,
    required String subcollection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(collection)
          .doc(documentId)
          .collection(subcollection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      print('❌ FirestoreService: Get subcollection failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    try {
      return _firestore
          .collection(collection)
          .doc(documentId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return doc.data();
        }
        return null;
      });
    } catch (e) {
      print('❌ FirestoreService: Stream document failed - $e');
      return Stream.error(e);
    }
  }

  /// Stream collection with query
  Stream<QuerySnapshot> streamCollection({
    required String collection,
    String? field,
    dynamic isEqualTo,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collection);

      // Add where clause
      if (field != null && isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }

      // Add ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Add limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots();
    } catch (e) {
      print('❌ FirestoreService: Stream collection failed - $e');
      return Stream.error(e);
    }
  }

  /// Stream subcollection
  Stream<QuerySnapshot> streamSubcollection({
    required String collection,
    required String documentId,
    required String subcollection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      Query query = _firestore
          .collection(collection)
          .doc(documentId)
          .collection(subcollection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots();
    } catch (e) {
      print('❌ FirestoreService: Stream subcollection failed - $e');
      return Stream.error(e);
    }
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Execute batch write
  Future<void> executeBatch(List<BatchOperation> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore
            .collection(operation.collection)
            .doc(operation.documentId);

        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(docRef, operation.data!, SetOptions(merge: operation.merge));
            break;
          case BatchOperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      print('❌ FirestoreService: Execute batch failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // TRANSACTION OPERATIONS
  // ============================================================================

  /// Execute transaction
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction transaction) updateFunction,
      ) async {
    try {
      return await _firestore.runTransaction<T>(updateFunction);
    } catch (e) {
      print('❌ FirestoreService: Run transaction failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if document exists
  Future<bool> documentExists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('❌ FirestoreService: Document exists check failed - $e');
      return false;
    }
  }

  /// Get document count
  Future<int> getDocumentCount({
    required String collection,
    String? field,
    dynamic isEqualTo,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (field != null && isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ FirestoreService: Get document count failed - $e');
      return 0;
    }
  }

  /// Generate new document ID
  String generateDocumentId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

  /// Get server timestamp
  FieldValue getServerTimestamp() {
    return FieldValue.serverTimestamp();
  }
}

// ============================================================================
// BATCH OPERATION CLASSES
// ============================================================================

enum BatchOperationType { set, update, delete }

class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;

  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
    this.merge = false,
  });

  /// Create set operation
  factory BatchOperation.set({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.set,
      data: data,
      merge: merge,
    );
  }

  /// Create update operation
  factory BatchOperation.update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.update,
      data: data,
    );
  }

  /// Create delete operation
  factory BatchOperation.delete({
    required String collection,
    required String documentId,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.delete,
    );
  }
}