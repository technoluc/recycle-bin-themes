# De URL van het aangepaste icoon
$iconPath = "https://raw.githubusercontent.com/technoluc/winutil/main/icons/TL.png"

# De URL van de GitHub-repo voor thema's
$repoUrl = "https://api.github.com/repos/technoluc/recycle-bin-themes/contents/themes"

# De URL van img1
$img1Path = "https://raw.githubusercontent.com/technoluc/recycle-bin-themes/main/assets/bin.jpg"


# Haal de lijst met thema's op van de GitHub-repo
$themesJson = Invoke-RestMethod -Uri $repoUrl

# Maak een lege hashtable om de themanamen op te slaan, waarbij de GitHub-namen worden gekoppeld aan de gewenste weergavenamen
$themeNames = @{}

# Voeg feedback toe aan de gebruiker
function ShowMessage($message) {
  [System.Windows.MessageBox]::Show($message, "Notification", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

# Importeer de TextInfo-klasse om ToTitleCase te kunnen gebruiken
Add-Type -AssemblyName System.Globalization

# Loop door de lijst met thema's en voeg ze toe aan de array
foreach ($theme in $themesJson) {
  # Hier krijgen we de naam van het thema uit de "name" eigenschap van het thema-object
  $themeName = $theme.name
  # Write-Host "Verwerken van thema: $themeName"
  if ($theme.type -eq "dir") {
    # Hier gebruiken we ToTitleCase om de eerste letter van elk woord te kapitaliseren
    $textInfo = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo
    $displayName = $textInfo.ToTitleCase($themeName) -replace '-', ' '
    $themeNames[$themeName] = $displayName
  }
}
# Definieer de functie om het standaardpictogram van de prullenbak te wijzigen
function writeToDefaultIconRegistry {
  param (
    $name,
    $value 
  )
  Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon" -Name "$name" -Value "$value"
}

function Set-RecycleBinIcon {
  param (
    $emptyIconPath,
    $fullIconPath
  )
  
  try {
    # Instellingen voor standaardpictogrammen
    writeToDefaultIconRegistry "(Default)" "$emptyIconPath,0"
    writeToDefaultIconRegistry "full" "$fullIconPath,0"
    writeToDefaultIconRegistry "empty" "$emptyIconPath,0"
      
    # Herstart Windows Verkenner om de wijzigingen door te voeren
    Stop-Process -Name explorer -Force
    ShowMessage "Recycle Bin Theme set to: $selectedDisplayName."
  }
  catch {
    Write-Host "Fout bij het instellen van het pictogram: $_"
  }
}

# Maak een WPF-venster voor themaselectie
Add-Type -AssemblyName PresentationFramework
$window = New-Object Windows.Window
$window.Title = "TechnoLuc's RecycleBinThemes"
$window.ResizeMode = "CanResizeWithGrip"  # Hier kun je ResizeMode naar wens instellen
$window.Width = 750  # Pas de breedte aan zoals gewenst
$window.Height = 600  # Pas de hoogte aan zoals gewenst
$window.WindowStartupLocation = "CenterScreen"  # Centreren op het scherm // Manual / CenterScreen
# $window.WindowState = [System.Windows.WindowState]::Maximized  # Maximaliseer het venster bij het starten

# Stel het venster-icoon in op het aangepaste icoon
$window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($iconPath))

# Voeg een Grid-element toe aan het venster om de lay-out te beheren
$grid = New-Object Windows.Controls.Grid

# Voeg een kolom toe voor het img1 en de standaardknop en stel deze in op "Star" (even breed)
$column1 = New-Object Windows.Controls.ColumnDefinition
$column1.Width = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)
$grid.ColumnDefinitions.Add($column1)

# Voeg een kolom toe voor de themalijst en de knop Toepassen en stel deze in op "Star" (even breed)
$column2 = New-Object Windows.Controls.ColumnDefinition
$column2.Width = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)
$grid.ColumnDefinitions.Add($column2)

# Voeg een rij toe voor het img1 en de themalijst met een relatieve hoogte (1*) zodat ze schalen
$row1 = New-Object Windows.Controls.RowDefinition
$row1.Height = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)
$grid.RowDefinitions.Add($row1)

# Voeg een rij toe voor de standaardknop en de knop Toepassen met een relatieve hoogte (1*) zodat ze schalen
$row2 = New-Object Windows.Controls.RowDefinition
$row2.Height = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)
$grid.RowDefinitions.Add($row2)

# Voeg een img1 toe aan het venster
$img1 = New-Object Windows.Controls.Image
$img1.Source = [System.Windows.Media.Imaging.BitmapImage]::new([System.Uri]"$img1Path")
$img1.Margin = "10"
$img1.Width = 400 # Pas de breedte van het img1 hier aan
$img1.Height = 400 # Pas de hoogte van het img1 hier aan

# Voeg een knop "Standaard" toe aan het venster
$defaultButton = New-Object Windows.Controls.Button
$defaultButton.Content = "Default"
$defaultButton.Margin = "10"
$defaultButton.Add_Click({
    try {
      # Standaardpictogrammen instellen
      writeToDefaultIconRegistry "empty" "%SystemRoot%\System32\imageres.dll,-55"
      writeToDefaultIconRegistry "full" "%SystemRoot%\System32\imageres.dll,-54"
      
      # Herstart Windows Verkenner om de wijzigingen door te voeren
      Stop-Process -Name explorer -Force

      ShowMessage "Recycle Bin restored to default theme."
    }
    catch {
      Write-Host "Fout bij het herstellen van de standaardpictogrammen: $_"
    }
  })

# Voeg een tekstblok toe aan het venster
$textBlock = New-Object Windows.Controls.TextBlock
$textBlock.Text = 'Select a theme and press "Apply"'
$textBlock.Margin = "10"

# Voeg een lijstvak toe aan het venster
$listBox = New-Object Windows.Controls.ListBox
$listBox.Margin = "10"

# Voeg themanamen toe aan het lijstvak (gebruik de gewenste weergavenaam) en sorteer ze alfabetisch
$sortedThemeNames = $themeNames.Values | Sort-Object
foreach ($themeName in $sortedThemeNames) {
  $listBox.Items.Add($themeName) > $null
}

# Voeg een knop "Toepassen" toe aan het venster
$applyButton = New-Object Windows.Controls.Button 
$applyButton.Content = "Apply"
$applyButton.Margin = "10"
$applyButton.Add_Click({
    $choice = $listBox.SelectedIndex + 1
    if ($choice -gt 0) {
      # Haal de geselecteerde thema-naam op basis van de weergavenaam
      $selectedDisplayName = $listBox.SelectedItem
      $selectedThemeName = $themeNames.GetEnumerator() | Where-Object { $_.Value -eq $selectedDisplayName } | Select-Object -ExpandProperty Key

      # Haal de geselecteerde thema-URL's op
      $selected_theme = $selectedThemeName
      $empty_icon_url = "https://raw.githubusercontent.com/technoluc/recycle-bin-themes/main/themes/$selected_theme/$selected_theme-empty.ico"
      $full_icon_url = "https://raw.githubusercontent.com/technoluc/recycle-bin-themes/main/themes/$selected_theme/$selected_theme-full.ico"

      # Download de iconen naar een tijdelijke map
      $tempPath = [System.IO.Path]::GetTempPath()
      $empty_icon_path = Join-Path -Path $tempPath -ChildPath "$selected_theme-empty.ico"
      $full_icon_path = Join-Path -Path $tempPath -ChildPath "$selected_theme-full.ico"

      try {
        # Download de iconen
        Invoke-WebRequest -Uri $empty_icon_url -OutFile $empty_icon_path
        Invoke-WebRequest -Uri $full_icon_url -OutFile $full_icon_path

        # Roep de functie aan om pictogrammen in te stellen
        Set-RecycleBinIcon -emptyIconPath $empty_icon_path -fullIconPath $full_icon_path
      }
      catch {
        Write-Host "Fout bij het downloaden en instellen van het pictogram: $_"
      }
    }
  })

# Voeg de elementen toe aan het venster
$grid.Children.Add($img1) > $null
$grid.Children.Add($defaultButton) > $null
$grid.Children.Add($textBlock) > $null
$grid.Children.Add($listBox) > $null
$grid.Children.Add($applyButton) > $null

# Stel de positie van elk element in
[Windows.Controls.Grid]::SetColumn($img1, 1)
[Windows.Controls.Grid]::SetColumn($defaultButton, 1)
[Windows.Controls.Grid]::SetColumn($textBlock, 0)
[Windows.Controls.Grid]::SetColumn($listBox, 0)
[Windows.Controls.Grid]::SetColumn($applyButton, 0)
[Windows.Controls.Grid]::SetRow($img1, 0)
[Windows.Controls.Grid]::SetRow($defaultButton, 1)
[Windows.Controls.Grid]::SetRow($textBlock, 1)
[Windows.Controls.Grid]::SetRow($listBox, 0)
[Windows.Controls.Grid]::SetRow($applyButton, 1)

# Voeg het Grid-element toe aan het venster
$window.Content = $grid


# Voeg error handling toe
trap {
  Write-Host "Er is een fout opgetreden: $_"
  break
}

# Voeg een event handler toe voor het SizeChanged evenement van het venster
$window.Add_SizeChanged({
    # Bepaal de nieuwe hoogte en breedte van het venster
    $newWidth = $window.ActualWidth
    $newHeight = $window.ActualHeight

    # Bereken de nieuwe grootte van het img1 op basis van de nieuwe hoogte en breedte
    $img1SizeFactor = [Math]::Min($newWidth / 800, $newHeight / 600)  # Hier kun je 800 en 600 aanpassen aan de oorspronkelijke grootte van het img1
    $img1.Width = 300 * $img1SizeFactor
    $img1.Height = 300 * $img1SizeFactor

    # Bereken de nieuwe grootte van de knoppen op basis van de nieuwe hoogte en breedte
    $buttonSizeFactor = [Math]::Min($newWidth / 800, $newHeight / 600)  # Hier kun je 800 en 600 aanpassen aan de oorspronkelijke grootte van het venster
    $buttonWidth = 100 * $buttonSizeFactor
    $buttonHeight = 100 * $buttonSizeFactor

    # Pas de breedte en hoogte van de knoppen aan
    $defaultButton.Width = $buttonWidth
    $defaultButton.Height = $buttonHeight
    $applyButton.Width = $buttonWidth
    $applyButton.Height = $buttonHeight

    # Voeg hier verdere aanpassingen van de grootte van elementen toe indien nodig

    # Zorg ervoor dat de elementen opnieuw worden weergegeven
    $window.UpdateLayout()
  })


# Toon het venster
$window.ShowDialog() > $null
