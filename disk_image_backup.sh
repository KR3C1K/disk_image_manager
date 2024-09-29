#!/bin/bash

# Ustal rozmiar bloku dla szybszej operacji (1M = 1 megabajt)
# Set block size for faster operation (1M = 1 megabyte)
BLOCK_SIZE="1M"

# Funkcja do instalacji brakujących pakietów
# Function to install missing packages
install_missing_package() {
  PACKAGE_NAME="$1"
  if [ "$LANGUAGE" == "pl" ]; then
    echo -e "\033[31mBrak komendy $PACKAGE_NAME, instaluję ją...\033[0m"  # Red color
  else
    echo -e "\033[31mMissing command $PACKAGE_NAME, installing it...\033[0m"  # Red color
  fi
  sudo apt-get install "$PACKAGE_NAME" -y || sudo yum install "$PACKAGE_NAME" -y || sudo dnf install "$PACKAGE_NAME" -y || sudo pacman -S "$PACKAGE_NAME" --noconfirm
}

# Funkcja do sprawdzania wymaganych poleceń
# Function to check for required commands
check_command() {
  COMMAND_NAME="$1"
  COMMAND_DESCRIPTION="$2"
  if ! command -v "$COMMAND_NAME" &> /dev/null; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mBrak narzędzia $COMMAND_DESCRIPTION. Aby je zainstalować, użyj polecenia:\033[0m"  # Red color
    else
      echo -e "\033[31mMissing tool $COMMAND_DESCRIPTION. To install it, use the command:\033[0m"  # Red color
    fi
    case "$COMMAND_NAME" in
      pv)
        echo "  sudo apt-get install pv  # for Debian/Ubuntu"
        echo "  sudo yum install pv      # for RedHat/CentOS"
        echo "  sudo dnf install pv      # for Fedora"
        echo "  sudo pacman -S pv        # for Arch Linux"
        ;;
      bc)
        echo "  sudo apt-get install bc   # for Debian/Ubuntu"
        echo "  sudo yum install bc       # for RedHat/CentOS"
        echo "  sudo dnf install bc       # for Fedora"
        echo "  sudo pacman -S bc         # for Arch Linux"
        ;;
      dd)
        echo "  sudo apt-get install coreutils  # for Debian/Ubuntu"
        echo "  sudo yum install coreutils       # for RedHat/CentOS"
        echo "  sudo dnf install coreutils       # for Fedora"
        echo "  sudo pacman -S coreutils         # for Arch Linux"
        ;;
    esac
    exit 1
  fi
}

# Wybór języka
# Language selection
echo -e "\033[1;34mWybierz język / Choose language:\033[0m"  # Blue bold text
echo "1. Polski"
echo "2. English"
read -r lang_option
if [ "$lang_option" == "1" ]; then
  LANGUAGE="pl"
  echo -e "\033[1;32mWybrano język polski.\033[0m"  # Green color
else
  LANGUAGE="en"
  echo -e "\033[1;32mSelected English language.\033[0m"  # Green color
fi

# Sprawdzenie wymaganych narzędzi
# Check for required tools
check_command pv "pv"
check_command bc "bc"
check_command dd "dd"

# Funkcja do tworzenia obrazu dysku
# Function to create a disk image
create_disk_image() {
  SOURCE_DEVICE="$1"
  FULL_OUTPUT_PATH="$2"
  # Sprawdzenie, czy urządzenie źródłowe istnieje
  # Check if the source device exists
  if [ ! -e "$SOURCE_DEVICE" ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mUrządzenie źródłowe $SOURCE_DEVICE nie istnieje.\033[0m"  # Red color
    else
      echo -e "\033[31mSource device $SOURCE_DEVICE does not exist.\033[0m"  # Red color
    fi
    return 1
  fi
  # Sprawdzenie, czy katalog docelowy istnieje, w przeciwnym razie próbujemy go utworzyć
  # Check if the destination directory exists, if not, attempt to create it
  DEST_PATH=$(dirname "$FULL_OUTPUT_PATH")
  if [ ! -d "$DEST_PATH" ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[33mŚcieżka $DEST_PATH nie istnieje. Tworzę ścieżkę...\033[0m"  # Yellow color
    else
      echo -e "\033[33mPath $DEST_PATH does not exist. Creating the path...\033[0m"  # Yellow color
    fi
    mkdir -p "$DEST_PATH"
    if [ $? -ne 0 ]; then
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[31mNie udało się utworzyć ścieżki $DEST_PATH.\033[0m"  # Red color
      else
        echo -e "\033[31mFailed to create path $DEST_PATH.\033[0m"  # Red color
      fi
      return 1
    fi
  fi
  # Pobierz całkowity rozmiar dysku
  # Get total size of the disk
  TOTAL_SIZE_BYTES=$(blockdev --getsize64 "$SOURCE_DEVICE")
  TOTAL_SIZE_MB=$(echo "$TOTAL_SIZE_BYTES / 1024 / 1024" | bc)
  if [ "$LANGUAGE" == "pl" ]; then
    echo -e "\033[1;36mCałkowita pojemność dysku: $TOTAL_SIZE_MB MB\033[0m"  # Cyan color
    echo -e "\033[1;34mRozpoczynam tworzenie obrazu dysku z $SOURCE_DEVICE do $FULL_OUTPUT_PATH...\033[0m"  # Blue bold text
  else
    echo -e "\033[1;36mTotal disk capacity: $TOTAL_SIZE_MB MB\033[0m"  # Cyan color
    echo -e "\033[1;34mStarting to create disk image from $SOURCE_DEVICE to $FULL_OUTPUT_PATH...\033[0m"  # Blue bold text
  fi
  # Użyj pv do monitorowania postępu
  # Use pv to monitor progress
  pv -s "$TOTAL_SIZE_BYTES" "$SOURCE_DEVICE" | dd of="$FULL_OUTPUT_PATH" bs="$BLOCK_SIZE" status=none
  if [ $? -eq 0 ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[1;32mObraz dysku został pomyślnie utworzony: $FULL_OUTPUT_PATH\033[0m"  # Green color
    else
      echo -e "\033[1;32mDisk image has been successfully created: $FULL_OUTPUT_PATH\033[0m"  # Green color
    fi
  else
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mWystąpił błąd podczas tworzenia obrazu dysku.\033[0m"  # Red color
    else
      echo -e "\033[31mAn error occurred while creating the disk image.\033[0m"  # Red color
    fi
  fi
}

# Funkcja do przywracania obrazu dysku
# Function to restore a disk image
restore_disk_image() {
  SOURCE_IMAGE="$1"
  DEST_DEVICE="$2"
  # Sprawdzenie, czy plik obrazu istnieje
  # Check if the image file exists
  if [ ! -e "$SOURCE_IMAGE" ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mPlik obrazu $SOURCE_IMAGE nie istnieje.\033[0m"  # Red color
    else
      echo -e "\033[31mImage file $SOURCE_IMAGE does not exist.\033[0m"  # Red color
    fi
    return 1
  fi
  # Sprawdzenie, czy urządzenie docelowe istnieje
  # Check if the destination device exists
  if [ ! -e "$DEST_DEVICE" ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mUrządzenie docelowe $DEST_DEVICE nie istnieje.\033[0m"  # Red color
    else
      echo -e "\033[31mDestination device $DEST_DEVICE does not exist.\033[0m"  # Red color
    fi
    return 1
  fi
  if [ "$LANGUAGE" == "pl" ]; then
    echo -e "\033[1;34mRozpoczynam przywracanie obrazu dysku z $SOURCE_IMAGE do $DEST_DEVICE...\033[0m"  # Blue bold text
  else
    echo -e "\033[1;34mStarting to restore disk image from $SOURCE_IMAGE to $DEST_DEVICE...\033[0m"  # Blue bold text
  fi
  # Użyj pv do monitorowania postępu
  # Use pv to monitor progress
  pv "$SOURCE_IMAGE" | dd of="$DEST_DEVICE" bs="$BLOCK_SIZE" status=none
  if [ $? -eq 0 ]; then
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[1;32mObraz dysku został pomyślnie przywrócony: $DEST_DEVICE\033[0m"  # Green color
    else
      echo -e "\033[1;32mDisk image has been successfully restored: $DEST_DEVICE\033[0m"  # Green color
    fi
  else
    if [ "$LANGUAGE" == "pl" ]; then
      echo -e "\033[31mWystąpił błąd podczas przywracania obrazu dysku.\033[0m"  # Red color
    else
      echo -e "\033[31mAn error occurred while restoring the disk image.\033[0m"  # Red color
    fi
  fi
}

# Menu główne
# Main menu
while true; do
  echo -e "\033[1;33m\n============================\033[0m"  # Yellow color
  if [ "$LANGUAGE" == "pl" ]; then
    echo -e "\033[1;35mMENU KOPII DYSKU\033[0m"  # Magenta color
  else
    echo -e "\033[1;35mDISK BACKUP MENU\033[0m"  # Magenta color
  fi
  echo -e "\033[1;33m============================\033[0m"  # Yellow color
  if [ "$LANGUAGE" == "pl" ]; then
    echo "1. Kopiuj dysk"
    echo "2. Przywróć kopię dysku"
    echo "3. Wyjście"
  else
    echo "1. Copy disk"
    echo "2. Restore disk image"
    echo "3. Exit"
  fi
  read -r option
  case "$option" in
    1)
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[1;34mPodaj dysk źródłowy (np. /dev/sda): \033[0m"  # Blue color
      else
        echo -e "\033[1;34mEnter the source disk (e.g. /dev/sda): \033[0m"  # Blue color
      fi
      read -r source_disk
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[1;34mPodaj pełną ścieżkę do pliku obrazu (np. /mnt/Data/win11.img): \033[0m"  # Blue color
      else
        echo -e "\033[1;34mEnter the full path to the image file (e.g. /mnt/Data/win11.img): \033[0m"  # Blue color
      fi
      read -r output_path
      create_disk_image "$source_disk" "$output_path"
      ;;
    2)
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[1;34mPodaj ścieżkę do pliku obrazu (np. /mnt/Data/win11.img): \033[0m"  # Blue color
      else
        echo -e "\033[1;34mEnter the path to the image file (e.g. /mnt/Data/win11.img): \033[0m"  # Blue color
      fi
      read -r source_image
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[1;34mPodaj docelowy dysk (np. /dev/sda): \033[0m"  # Blue color
      else
        echo -e "\033[1;34mEnter the destination disk (e.g. /dev/sda): \033[0m"  # Blue color
      fi
      read -r dest_disk
      restore_disk_image "$source_image" "$dest_disk"
      ;;
    3)
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[1;32mWyjście z programu.\033[0m"  # Green color
      else
        echo -e "\033[1;32mExiting the program.\033[0m"  # Green color
      fi
      exit 0
      ;;
    *)
      if [ "$LANGUAGE" == "pl" ]; then
        echo -e "\033[31mNiepoprawna opcja, spróbuj ponownie.\033[0m"  # Red color
      else
        echo -e "\033[31mInvalid option, please try again.\033[0m"  # Red color
      fi
      ;;
  esac
done
