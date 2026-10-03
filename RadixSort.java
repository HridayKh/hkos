import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class RadixSort {
	@SuppressWarnings("unchecked")
	private static final List<Integer>[] buckets = new ArrayList[256];

	public static void main(String[] args) {
		long istart = System.nanoTime();

		int size = 1 << 20; // 2^20 = 1,048,576
		int RUNS = 100;	 // Number of benchmark iterations per category
		Random rand = new Random(42); // Fixed seed for reproducible benchmarks

		for (int i = 0; i < 256; i++) {
			buckets[i] = new ArrayList<>();
		}

		System.out.printf("Initialization time: %.6f ms\n\n", (System.nanoTime() - istart) / 1e6);

		double[] posTimes = new double[RUNS];
		double[] negTimes = new double[RUNS];

		// 1. Warmup Run (Optional, helps JIT compiler optimize hot paths before timing)
		for (int i = 0; i < 5; i++) {
			int[] warmupArr = new int[size];
			radixSort(warmupArr, size);
			negRadixSort(warmupArr, size);
		}

		// ==========================================
		// 1. BENCHMARK: Positive Only (radixSort)
		// ==========================================
		System.out.println("Benchmarking radixSort (+ve only) across " + RUNS + " runs...");
		for (int run = 0; run < RUNS; run++) {
			int[] arr = new int[size];
			for (int i = 0; i < size; i++) {
				arr[i] = rand.nextInt(Integer.MAX_VALUE); // Positive integers only
			}

			long start = System.nanoTime();
			radixSort(arr, size);
			long end = System.nanoTime();

			posTimes[run] = (end - start) / 1e6; // Store time in ms
		}

		// ==========================================
		// 2. BENCHMARK: Negative + Positive (negRadixSort)
		// ==========================================
		System.out.println("Benchmarking negRadixSort (Signed) across " + RUNS + " runs...");
		for (int run = 0; run < RUNS; run++) {
			int[] arr = new int[size];
			for (int i = 0; i < size; i++) {
				arr[i] = rand.nextInt(); // Full range signed integers
			}

			long start = System.nanoTime();
			negRadixSort(arr, size);
			long end = System.nanoTime();

			negTimes[run] = (end - start) / 1e6; // Store time in ms
		}

		// ==========================================
		// 3. STATISTICAL REPORTING
		// ==========================================
		System.out.println("\n" + "=".repeat(50));
		printStats("radixSort (+ve only)", posTimes);
		System.out.println("-".repeat(50));
		printStats("negRadixSort (Signed)", negTimes);
		System.out.println("=".repeat(50));
	}

	private static void printStats(String label, double[] times) {
		double sum = 0.0;
		double min = Double.MAX_VALUE;
		double max = Double.MIN_VALUE;

		for (double t : times) {
			sum += t;
			if (t < min) min = t;
			if (t > max) max = t;
		}

		double avg = sum / times.length;

		// Calculate standard deviation
		double varianceSum = 0.0;
		for (double t : times) {
			varianceSum += Math.pow(t - avg, 2);
		}
		double stdDev = Math.sqrt(varianceSum / times.length);

		// Compute median
		double[] sortedTimes = times.clone();
		Arrays.sort(sortedTimes);
		double median = (times.length % 2 == 0)
				? (sortedTimes[times.length / 2 - 1] + sortedTimes[times.length / 2]) / 2.0
				: sortedTimes[times.length / 2];

		System.out.printf("Category : %s (%d runs)\n", label, times.length);
		System.out.printf("  Average : %.4f ms\n", avg);
		System.out.printf("  Median  : %.4f ms\n", median);
		System.out.printf("  Min	 : %.4f ms\n", min);
		System.out.printf("  Max	 : %.4f ms\n", max);
		System.out.printf("  Std Dev : %.4f ms\n", stdDev);
	}

	public static void radixSort(int[] arr, int n) {
		int[] temp = new int[n];
		
		int[] src = arr;
		int[] dest = temp;
		for (int shift = 0; shift < 32; shift += 8) {
			int[] count = new int[256];

			for (int i = 0; i < n; i++) {
			count[(src[i] >> shift) & 0xFF]++;
			}
			for (int i = 1; i < 256; i++) {
			count[i] += count[i - 1];
			}
			for (int i = n - 1; i >= 0; i--) {
			int digit = (src[i] >> shift) & 0xFF;
			dest[--count[digit]] = src[i];
			}

			int[] swap = src;
			src = dest;
			dest = swap;
		}
	}

	public static void negRadixSort(int[] arr, int n) {
		int[] temp = new int[n];

		// Passes 1 to 3: Standard 8-bit shifts (no XOR, no branch)
		pass(arr, temp, 0);
		pass(temp, arr, 8);
		pass(arr, temp, 16);

		// Pass 4 (shift 24): Flip MSB directly in the loop body (no ternary check)
		int[] count = new int[256];
		for (int i = 0; i < n; i++) 
			count[((temp[i] ^ 0x80000000) >> 24) & 0xFF]++;
		for (int i = 1; i < 256; i++) 
			count[i] += count[i - 1];
		for (int i = n - 1; i >= 0; i--) {
			int digit = ((temp[i] ^ 0x80000000) >> 24) & 0xFF;
			arr[--count[digit]] = temp[i];
		}
	}

	private static void pass(int[] src, int[] dest, int shift) {
		int n = src.length;
		int[] count = new int[256];
		for (int i = 0; i < n; i++) {
			count[(src[i] >> shift) & 0xFF]++;
		}
		for (int i = 1; i < 256; i++) {
			count[i] += count[i - 1];
		}
		for (int i = n - 1; i >= 0; i--) {
			int digit = (src[i] >> shift) & 0xFF;
			dest[--count[digit]] = src[i];
		}
	}
}