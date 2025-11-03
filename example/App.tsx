import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Image,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import {
  pickMedia,
  pickFiles,
  clearCachedFiles,
  isSystemPhotoPickerAvailable,
  PickedItem,
  PickError,
} from 'react-native-files-picker';

const { width } = Dimensions.get('window');

export default function App() {
  const [selectedItems, setSelectedItems] = useState<PickedItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [photoPickerAvailable, setPhotoPickerAvailable] = useState(false);

  useEffect(() => {
    checkPhotoPickerAvailability();
  }, []);

  const checkPhotoPickerAvailability = async () => {
    try {
      const available = await isSystemPhotoPickerAvailable();
      setPhotoPickerAvailable(available);
    } catch (error) {
      console.log('Failed to check photo picker availability:', error);
    }
  };

  const handlePickImages = async () => {
    setLoading(true);
    try {
      const items = await pickMedia('image', {
        multiple: true,
        copyToCache: true,
        stripEXIF: false,
      });
      setSelectedItems(items);
      if (items.length === 0) {
        Alert.alert('Canceled', 'No images selected');
      } else {
        Alert.alert('Success', `Picked ${items.length} image(s)`);
      }
    } catch (error) {
      const err = error as PickError;
      Alert.alert(
        'Error',
        `Failed to pick images: ${err.code} - ${err.message}`
      );
    } finally {
      setLoading(false);
    }
  };

  const handlePickVideos = async () => {
    setLoading(true);
    try {
      const items = await pickMedia('video', { multiple: true });
      setSelectedItems(items);
      Alert.alert('Success', `Picked ${items.length} video(s)`);
    } catch (error) {
      const err = error as PickError;
      Alert.alert('Error', `Failed to pick videos: ${err.code}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePickMixed = async () => {
    setLoading(true);
    try {
      const items = await pickMedia('mixed', { multiple: true });
      setSelectedItems(items);
      Alert.alert('Success', `Picked ${items.length} file(s)`);
    } catch (error) {
      const err = error as PickError;
      Alert.alert('Error', `Failed to pick media: ${err.code}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePickFiles = async () => {
    setLoading(true);
    try {
      const items = await pickFiles('any', { multiple: true });
      setSelectedItems(items);
      Alert.alert('Success', `Picked ${items.length} file(s)`);
    } catch (error) {
      const err = error as PickError;
      Alert.alert('Error', `Failed to pick files: ${err.code}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePickPDFs = async () => {
    setLoading(true);
    try {
      const items = await pickFiles('pdf', { multiple: true });
      setSelectedItems(items);
      Alert.alert('Success', `Picked ${items.length} PDF(s)`);
    } catch (error) {
      const err = error as PickError;
      Alert.alert('Error', `Failed to pick PDFs: ${err.code}`);
    } finally {
      setLoading(false);
    }
  };

  const handleClearCache = async () => {
    try {
      await clearCachedFiles();
      Alert.alert('Success', 'Cache cleared');
      setSelectedItems([]);
    } catch (error) {
      Alert.alert('Error', 'Failed to clear cache');
    }
  };

  const renderMediaItem = (item: PickedItem, index: number) => {
    const isImage = item.mimeType?.startsWith('image/');
    const isVideo = item.mimeType?.startsWith('video/');

    return (
      <View key={index} style={styles.itemContainer}>
        <View style={styles.itemHeader}>
          <Text style={styles.itemTitle}>{item.displayName || `Item ${index + 1}`}</Text>
          <Text style={styles.itemType}>{item.mimeType || 'unknown'}</Text>
        </View>

        {isImage && item.uri && (
          <Image
            source={{ uri: item.uri }}
            style={styles.thumbnail}
            onError={(e) => console.log('Image load error:', e)}
          />
        )}

        <View style={styles.itemDetails}>
          {item.uri && <Text style={styles.detailText}>URI: {item.uri}</Text>}
          {item.id && <Text style={styles.detailText}>ID: {item.id}</Text>}
          {item.size !== undefined && (
            <Text style={styles.detailText}>
              Size: {(item.size / 1024).toFixed(2)} KB
            </Text>
          )}
          {item.width !== undefined && item.height !== undefined && (
            <Text style={styles.detailText}>
              Dimensions: {item.width} × {item.height}px
            </Text>
          )}
          {item.durationMs !== undefined && (
            <Text style={styles.detailText}>
              Duration: {(item.durationMs / 1000).toFixed(2)}s
            </Text>
          )}
          {item.exifStripped && (
            <Text style={styles.detailText}>✓ EXIF Stripped</Text>
          )}
        </View>
      </View>
    );
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.title}>Zero Permission Picker</Text>
        <Text style={styles.subtitle}>
          Select files without storage permissions
        </Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Media Picking</Text>

        <TouchableOpacity
          style={[styles.button, styles.buttonPrimary]}
          onPress={handlePickImages}
          disabled={loading}
        >
          <Text style={styles.buttonText}>Pick Images</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.buttonPrimary]}
          onPress={handlePickVideos}
          disabled={loading}
        >
          <Text style={styles.buttonText}>Pick Videos</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.buttonPrimary]}
          onPress={handlePickMixed}
          disabled={loading}
        >
          <Text style={styles.buttonText}>Pick Mixed (Images & Videos)</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>File Picking</Text>

        <TouchableOpacity
          style={[styles.button, styles.buttonSecondary]}
          onPress={handlePickFiles}
          disabled={loading}
        >
          <Text style={styles.buttonText}>Pick Any Files</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.buttonSecondary]}
          onPress={handlePickPDFs}
          disabled={loading}
        >
          <Text style={styles.buttonText}>Pick PDFs</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Info</Text>
        <Text style={styles.infoText}>
          Photo Picker Available: {photoPickerAvailable ? '✓ Yes' : '✗ No'}
        </Text>
        <Text style={styles.infoText}>
          Selected Items: {selectedItems.length}
        </Text>
      </View>

      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      )}

      {selectedItems.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Selected Items</Text>
          {selectedItems.map((item, index) => renderMediaItem(item, index))}

          <TouchableOpacity
            style={[styles.button, styles.buttonDanger]}
            onPress={handleClearCache}
          >
            <Text style={styles.buttonText}>Clear Cache</Text>
          </TouchableOpacity>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    padding: 16,
  },
  header: {
    marginBottom: 32,
    marginTop: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  section: {
    marginBottom: 24,
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
    marginBottom: 12,
  },
  button: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 8,
    marginBottom: 8,
    alignItems: 'center',
  },
  buttonPrimary: {
    backgroundColor: '#007AFF',
  },
  buttonSecondary: {
    backgroundColor: '#5AC8FA',
  },
  buttonDanger: {
    backgroundColor: '#FF3B30',
    marginTop: 12,
  },
  buttonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  itemContainer: {
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  itemHeader: {
    marginBottom: 8,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
  },
  itemType: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  thumbnail: {
    width: width - 64,
    height: 200,
    borderRadius: 8,
    marginBottom: 8,
  },
  itemDetails: {
    gap: 4,
  },
  detailText: {
    fontSize: 12,
    color: '#666',
    fontFamily: 'Courier New',
  },
  infoText: {
    fontSize: 14,
    color: '#333',
    marginBottom: 8,
  },
  loadingContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 24,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: '#666',
  },
});
