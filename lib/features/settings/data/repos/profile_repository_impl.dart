import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_order_entity.dart';
import '../../domain/repos/profile_repository.dart';

import '../../../../core/core.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final InternetConnectionChecker connectionChecker;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectionChecker,
  });

  // تحقق من توفر الإنترنت
  Future<bool> _isConnected() async {
    return await connectionChecker.hasConnection;
  }

  @override
  Future<Either<ApiErrorModel, ProfileEntity>> getProfile() async {
    try {
      // محاولة جلب البيانات من الخادم أولاً
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.getProfile();

        return remoteResult.fold(
          (error) async {
            // في حالة الخطأ، جلب البيانات من التخزين المحلي
            final localResult = await localDataSource.getCachedProfile();

            return localResult.fold((cacheError) => Left(cacheError), (
              cachedProfile,
            ) {
              if (cachedProfile != null) {
                return Right(cachedProfile);
              } else {
                return Left(error);
              }
            });
          },
          (profile) async {
            // تخزين البيانات في التخزين المحلي
            await localDataSource.cacheProfile(profile);
            return Right(profile);
          },
        );
      } else {
        // في حالة عدم وجود إنترنت، جلب البيانات من التخزين المحلي
        final localResult = await localDataSource.getCachedProfile();

        return localResult.fold((error) => Left(error), (cachedProfile) {
          if (cachedProfile != null) {
            return Right(cachedProfile);
          } else {
            return Left(
              ApiErrorModel(
                errorMessage: ErrorData(
                  message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
                  code: 0,
                ),
                status: false,
              ),
            );
          }
        });
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, bool>> updateProfile(
    ProfileEntity profile,
  ) async {
    try {
      if (await _isConnected()) {
        // تحويل الكيان إلى نموذج البيانات
        final profileModel = ProfileModel.fromEntity(profile);

        // تحديث البيانات على الخادم
        final remoteResult = await remoteDataSource.updateProfile(profileModel);

        return remoteResult.fold((error) => Left(error), (success) async {
          if (success) {
            // تحديث البيانات في التخزين المحلي
            await localDataSource.cacheProfile(profileModel);
          }
          return Right(success);
        });
      } else {
        return Left(
          ApiErrorModel(
            errorMessage: ErrorData(
              message: 'لا يوجد اتصال بالإنترنت',
              code: 0,
            ),
            status: false,
          ),
        );
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, List<UserOrderEntity>>> getUserOrders() async {
    try {
      // محاولة جلب البيانات من الخادم أولاً
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.getUserOrders();

        return remoteResult.fold(
          (error) async {
            // في حالة الخطأ، جلب البيانات من التخزين المحلي
            final localResult = await localDataSource.getCachedOrders();

            return localResult.fold((cacheError) => Left(cacheError), (
              cachedOrders,
            ) {
              if (cachedOrders != null && cachedOrders.isNotEmpty) {
                return Right(cachedOrders);
              } else {
                return Left(error);
              }
            });
          },
          (orders) async {
            // تخزين البيانات في التخزين المحلي
            await localDataSource.cacheOrders(orders);
            return Right(orders);
          },
        );
      } else {
        // في حالة عدم وجود إنترنت، جلب البيانات من التخزين المحلي
        final localResult = await localDataSource.getCachedOrders();

        return localResult.fold((error) => Left(error), (cachedOrders) {
          if (cachedOrders != null && cachedOrders.isNotEmpty) {
            return Right(cachedOrders);
          } else {
            return Left(
              ApiErrorModel(
                errorMessage: ErrorData(
                  message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
                  code: 0,
                ),
                status: false,
              ),
            );
          }
        });
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, UserOrderEntity>> getOrderDetails(
    String orderId,
  ) async {
    try {
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.getOrderDetails(orderId);

        return remoteResult.fold(
          (error) => Left(error),
          (orderDetails) => Right(orderDetails),
        );
      } else {
        // في حالة عدم وجود إنترنت، محاولة البحث في المشتريات المخزنة
        final localResult = await localDataSource.getCachedOrders();

        return localResult.fold((error) => Left(error), (cachedOrders) {
          if (cachedOrders != null && cachedOrders.isNotEmpty) {
            final order =
                cachedOrders.where((o) => o.id == orderId).firstOrNull;
            if (order != null) {
              return Right(order);
            }
          }

          return Left(
            ApiErrorModel(
              errorMessage: ErrorData(
                message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
                code: 0,
              ),
              status: false,
            ),
          );
        });
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, List<LibraryItemEntity>>>
  getLibraryItems() async {
    try {
      // محاولة جلب البيانات من الخادم أولاً
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.getLibraryItems();

        return remoteResult.fold(
          (error) async {
            // في حالة الخطأ، جلب البيانات من التخزين المحلي
            final localResult = await localDataSource.getCachedLibraryItems();

            return localResult.fold((cacheError) => Left(cacheError), (
              cachedItems,
            ) {
              if (cachedItems != null && cachedItems.isNotEmpty) {
                return Right(cachedItems);
              } else {
                return Left(error);
              }
            });
          },
          (items) async {
            // تخزين البيانات في التخزين المحلي
            await localDataSource.cacheLibraryItems(items);
            return Right(items);
          },
        );
      } else {
        // في حالة عدم وجود إنترنت، جلب البيانات من التخزين المحلي
        final localResult = await localDataSource.getCachedLibraryItems();

        return localResult.fold((error) => Left(error), (cachedItems) {
          if (cachedItems != null && cachedItems.isNotEmpty) {
            return Right(cachedItems);
          } else {
            return Left(
              ApiErrorModel(
                errorMessage: ErrorData(
                  message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
                  code: 0,
                ),
                status: false,
              ),
            );
          }
        });
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, LibraryItemEntity>> getLibraryItemDetails(
    String itemId,
  ) async {
    try {
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.getLibraryItemDetails(
          itemId,
        );

        return remoteResult.fold(
          (error) => Left(error),
          (itemDetails) => Right(itemDetails),
        );
      } else {
        // في حالة عدم وجود إنترنت، محاولة البحث في المكتبة المخزنة
        final localResult = await localDataSource.getCachedLibraryItems();

        return localResult.fold((error) => Left(error), (cachedItems) {
          if (cachedItems != null && cachedItems.isNotEmpty) {
            final item = cachedItems.where((i) => i.id == itemId).firstOrNull;
            if (item != null) {
              return Right(item);
            }
          }

          return Left(
            ApiErrorModel(
              errorMessage: ErrorData(
                message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
                code: 0,
              ),
              status: false,
            ),
          );
        });
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, String>> downloadLibraryItem(
    String itemId,
  ) async {
    try {
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.downloadLibraryItem(itemId);

        return remoteResult.fold(
          (error) => Left(error),
          (fileUrl) => Right(fileUrl),
        );
      } else {
        return Left(
          ApiErrorModel(
            errorMessage: ErrorData(
              message: 'لا يوجد اتصال بالإنترنت، يجب الاتصال للتحميل',
              code: 0,
            ),
            status: false,
          ),
        );
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, bool>> sendSupportMessage(String message) async {
    try {
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.sendSupportMessage(message);

        return remoteResult.fold(
          (error) => Left(error),
          (success) => Right(success),
        );
      } else {
        return Left(
          ApiErrorModel(
            errorMessage: ErrorData(
              message: 'لا يوجد اتصال بالإنترنت، يرجى المحاولة لاحقاً',
              code: 0,
            ),
            status: false,
          ),
        );
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }

  @override
  Future<Either<ApiErrorModel, bool>> removeProfileImage() async {
    try {
      if (await _isConnected()) {
        final remoteResult = await remoteDataSource.removeProfileImage();
        return remoteResult.fold(
          (error) => Left(error),
          (success) => Right(success),
        );
      } else {
        return Left(
          ApiErrorModel(
            errorMessage: ErrorData(
              message: 'لا يوجد اتصال بالإنترنت، يرجى المحاولة لاحقاً',
              code: 0,
            ),
            status: false,
          ),
        );
      }
    } catch (e) {
      return Left(
        ApiErrorModel(
          errorMessage: ErrorData(message: 'حدث خطأ غير متوقع: $e', code: 500),
          status: false,
        ),
      );
    }
  }
  
  @override
  Future<Either<ApiErrorModel, String>> uploadProfileImage(File file) {
    // TODO: implement uploadProfileImage
    throw UnimplementedError();
  }

  }

  @override
  Future<Either<ApiErrorModel, String>> uploadProfileImage(File file) {
    // TODO: implement uploadProfileImage
    throw UnimplementedError();
  }

