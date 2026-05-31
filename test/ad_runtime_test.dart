import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/ads/ad_runtime.dart';

void main() {
  test('2GB-class Android devices do not disable ads', () {
    expect(
      AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: false,
        memoryClassMb: 256,
        availableMemoryMb: 600,
      ),
      isFalse,
    );
  });

  test('ads remain eligible on devices with enough memory', () {
    expect(
      AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: false,
        memoryClassMb: 256,
        availableMemoryMb: 700,
      ),
      isFalse,
    );
  });

  test('explicit Android low-RAM devices use conservative loading', () {
    expect(
      AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: true,
        memoryClassMb: 256,
        availableMemoryMb: 700,
      ),
      isTrue,
    );
  });

  test('critically constrained memory uses conservative loading', () {
    expect(
      AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: false,
        memoryClassMb: 128,
        availableMemoryMb: 700,
      ),
      isTrue,
    );
    expect(
      AdRuntimeDevicePolicy.shouldUseConservativeLoadingForLowResources(
        isLowRamDevice: false,
        memoryClassMb: 256,
        availableMemoryMb: 128,
      ),
      isTrue,
    );
  });
}
