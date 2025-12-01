import React, {useEffect, useMemo, useRef, useState} from 'react';
import {FlatList, StyleSheet, Text, TextInput, View} from 'react-native';
import {Terminal} from 'xterm-headless';
import {palette, spacing, typography} from '../theme/theme';
import {TerminalSize} from '../types/ssh';

interface TerminalViewProps {
  terminal: Terminal;
  size: TerminalSize;
  onInput: (text: string) => void;
  onResize?: (size: TerminalSize) => void;
}

export const TerminalView: React.FC<TerminalViewProps> = ({
  terminal,
  size,
  onInput,
  onResize,
}) => {
  const [lines, setLines] = useState<string[]>([]);
  const inputRef = useRef<TextInput>(null);

  useEffect(() => {
    const handler = () => {
      const buffer: string[] = [];
      for (let i = 0; i < terminal.buffer.length; i += 1) {
        buffer.push(terminal.buffer.getLine(i)?.translateToString() ?? '');
      }
      setLines(buffer);
    };
    terminal.onData(handler);
    handler();
    return () => terminal.offData(handler);
  }, [terminal]);

  useEffect(() => {
    onResize?.(size);
  }, [size, onResize]);

  const renderItem = useMemo(
    () => ({item}: {item: string}) => (
      <Text style={styles.line}>{item || ' '}</Text>
    ),
    [],
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={lines}
        renderItem={renderItem}
        keyExtractor={(item, index) => `${index}-${item}`}
        contentContainerStyle={styles.buffer}
      />
      <TextInput
        ref={inputRef}
        style={styles.input}
        autoCorrect={false}
        autoCapitalize="none"
        onChangeText={onInput}
        onFocus={() => inputRef.current?.clear()}
        placeholder="Type to send input"
        placeholderTextColor={palette.muted}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {flex: 1, backgroundColor: palette.background},
  buffer: {padding: spacing(2)},
  line: {
    fontFamily: typography.monospace,
    color: palette.text,
    fontSize: 14,
    lineHeight: 18,
  },
  input: {
    margin: spacing(2),
    padding: spacing(1),
    backgroundColor: palette.surface,
    color: palette.text,
    borderRadius: 6,
    fontFamily: typography.monospace,
  },
});
