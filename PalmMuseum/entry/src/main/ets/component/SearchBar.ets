@Component
export struct SearchBar {
  @State private searchText: string = '';
  @State private isFocused: boolean = false;
  private placeholder: string = '搜索文物名称、朝代、关键字...';
  onSearch?: (keyword: string) => void;
  onFocusChange?: (focused: boolean) => void;
  onVoiceSearch?: () => void;

  build() {
    Row({ space: 8 }) {
      // 搜索图标
      Text('🔍')
        .fontSize(18)
        .opacity(0.5)

      // 输入框
      TextInput({
        placeholder: this.placeholder,
        text: this.searchText
      })
        .layoutWeight(1)
        .fontSize(14)
        .placeholderColor($r('app.color.text_hint'))
        .onChange((value: string) => {
          this.searchText = value;
        })
        .onSubmit(() => {
          if (this.onSearch) {
            this.onSearch(this.searchText);
          }
        })
        .onFocus(() => {
          this.isFocused = true;
          if (this.onFocusChange) {
            this.onFocusChange(true);
          }
        })
        .onBlur(() => {
          this.isFocused = false;
          if (this.onFocusChange) {
            this.onFocusChange(false);
          }
        })
        .height(40)

      // 清除按钮
      if (this.searchText.length > 0) {
        Text('✕')
          .fontSize(16)
          .opacity(0.4)
          .onClick(() => {
            this.searchText = '';
          })
      }

      // 语音搜索按钮
      Button() {
        Text('🎤')
          .fontSize(18)
      }
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.search_bar_background'))
      .borderRadius(18)
      .onClick(() => {
        if (this.onVoiceSearch) {
          this.onVoiceSearch();
        }
      })
    }
    .padding({ left: 12, right: 8 })
    .backgroundColor($r('app.color.search_bar_background'))
    .borderRadius(20)
    .height(44)
  }
}
