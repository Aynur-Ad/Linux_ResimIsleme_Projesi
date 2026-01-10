#!/bin/bash

# =================================================================
# Proje: Linux Resim İşleme Atölyesi (ImageMagick Frontend)
# Ders: Linux Scriptleri ve Araçları
# Yazan: [Senin Adın]
# Tarih: 2026
# =================================================================

# --- 1. FONKSİYON: GEREKLİLİK KONTROLÜ ---
function kontrol_et() {
    araclar=("convert" "yad" "whiptail")
    for arac in "${araclar[@]}"; do
        if ! command -v $arac &> /dev/null; then
            echo "HATA: '$arac' paketi yüklü değil."
            echo "Lütfen yükleyin: sudo apt install imagemagick yad whiptail"
            exit 1
        fi
    done
}

# --- 2. FONKSİYON: RESİM İŞLEME MANTIĞI ---
function islemi_yap() {
    local dosya=$1
    local islem_id=$2
    local arayuz=$3 
    
    local klasor=$(dirname "$dosya")
    local dosya_adi=$(basename "$dosya")
    local uzantisiz="${dosya_adi%.*}"
    local sonuc_mesaji=""
    local yeni_dosya=""

    case $islem_id in
        1) # PNG Çevir
            yeni_dosya="$klasor/$uzantisiz.png"
            convert "$dosya" "$yeni_dosya"
            sonuc_mesaji="Format PNG yapıldı: $uzantisiz.png"
            ;;
        2) # %50 Küçült
            yeni_dosya="$klasor/kucuk_$dosya_adi"
            convert "$dosya" -resize 50% "$yeni_dosya"
            sonuc_mesaji="Resim %50 küçültüldü."
            ;;
        3) # Siyah Beyaz
            yeni_dosya="$klasor/sb_$dosya_adi"
            convert "$dosya" -colorspace Gray "$yeni_dosya"
            sonuc_mesaji="Siyah-Beyaz efekti uygulandı."
            ;;
        4) # 90 Derece Çevir
            yeni_dosya="$klasor/cevir_$dosya_adi"
            convert "$dosya" -rotate 90 "$yeni_dosya"
            sonuc_mesaji="Resim sağa 90 derece çevrildi."
            ;;
        5) # Çerçeve Ekle
            yeni_dosya="$klasor/cerceve_$dosya_adi"
            convert "$dosya" -bordercolor White -border 50x50 "$yeni_dosya"
            sonuc_mesaji="Resme beyaz çerçeve eklendi."
            ;;
    esac

    # Sonuç Mesajı
    if [ "$arayuz" == "gui" ]; then
        yad --info --title="İşlem Başarılı" \
            --text="<span font='11'><b>✅ $sonuc_mesaji</b></span>\n\nDosya Yolu:\n$yeni_dosya" \
            --width=400 --button="Tamam:0" 2> /dev/null
    else
        whiptail --msgbox "✅ $sonuc_mesaji\n\nDosya: $yeni_dosya" 10 60
    fi
}

# --- 3. FONKSİYON: GRAFİK ARAYÜZ (GUI) ---
function baslat_gui() {
    # 1. Dosya Seçimi
    DOSYA=$(yad --title="Resim Seç" --file-selection \
    --file-filter="Resimler | *.jpg *.png *.jpeg" \
    --width=600 --height=400 2> /dev/null)
    
    # İPTAL KONTROLÜ (YAD)
    if [ -z "$DOSYA" ]; then 
        yad --info --title="İptal" --text="❌ Dosya seçilmedi, işlem iptal edildi." --width=300 --button="Tamam:0" 2> /dev/null
        exit 0
    fi

    # 2. İşlem Seçimi
    ISLEM_SATIRI=$(yad --title="İşlem Menüsü" --list \
    --column="ID" --column="İşlem Özelliği" \
    1 "Formatı PNG Yap" \
    2 "Boyutlandır (%50 Küçült)" \
    3 "Siyah-Beyaz Yap" \
    4 "Sağa 90 Derece Çevir" \
    5 "Beyaz Çerçeve Ekle" \
    --height=350 --width=450 --print-column=1 --separator="" 2> /dev/null)
    
    # İPTAL KONTROLÜ (YAD)
    if [ -z "$ISLEM_SATIRI" ]; then 
        yad --info --title="İptal" --text="❌ İşlem seçilmedi, çıkılıyor." --width=300 --button="Tamam:0" 2> /dev/null
        exit 0
    fi
    
    islemi_yap "$DOSYA" "$ISLEM_SATIRI" "gui"
}

# --- 4. FONKSİYON: TERMINAL ARAYÜZ (TUI) ---
function baslat_tui() {
    # 1. Dosya Girişi
    DOSYA=$(whiptail --title "Resim Seçimi" --inputbox "Resim dosyasının adını/yolunu girin:" 10 60 3>&1 1>&2 2>&3)
    
    # İPTAL KONTROLÜ (Whiptail)
    if [ $? -ne 0 ]; then 
        whiptail --msgbox "❌ İşlem kullanıcı tarafından iptal edildi." 8 45
        exit 0
    fi

    if [ ! -f "$DOSYA" ]; then
        whiptail --msgbox "⚠️ HATA: Böyle bir dosya bulunamadı!" 8 45
        exit 1
    fi

    # 2. İşlem Seçimi
    SECIM=$(whiptail --title "İşlem Menüsü" --menu "Uygulanacak işlemi seçin:" 16 60 6 \
    "1" "Formatı PNG Yap" \
    "2" "Boyutlandır (%50 Küçült)" \
    "3" "Siyah-Beyaz Yap" \
    "4" "Sağa 90 Derece Çevir" \
    "5" "Beyaz Çerçeve Ekle" 3>&1 1>&2 2>&3)

    # İPTAL KONTROLÜ (Whiptail)
    if [ $? -ne 0 ]; then
        whiptail --msgbox "❌ İşlem seçilmedi, ana menüye dönülüyor..." 8 45
        exit 0
    fi

    islemi_yap "$DOSYA" "$SECIM" "tui"
}

# --- ANA PROGRAM ---
kontrol_et

MOD=$(whiptail --title "Linux Resim Atölyesi" --menu "Arayüz Seçimi Yapınız:" 15 60 2 \
"1" "Grafik Arayüz (GUI - YAD)" \
"2" "Terminal Arayüz (TUI - Whiptail)" 3>&1 1>&2 2>&3)

# İPTAL KONTROLÜ (Ana Menü)
if [ $? -ne 0 ]; then
    echo "Programdan çıkış yapıldı."
    exit 0
fi

case $MOD in
    1) baslat_gui ;;
    2) baslat_tui ;;
esac