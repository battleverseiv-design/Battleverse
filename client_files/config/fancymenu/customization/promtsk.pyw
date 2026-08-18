import os

def collect_all_sk_files(start_directory, output_file):
    """
    Агрессивный сканер. Использует os.walk для обхода вообще всех папок,
    независимо от глубины вложенности.
    """
    
    # Список для статистики
    found_files_list = []
    
    print(f"--- НАЧИНАЮ ПОИСК В: {os.path.abspath(start_directory)} ---")

    try:
        with open(output_file, 'w', encoding='utf-8') as outfile:
            # os.walk проходит по дереву каталогов сверху вниз
            for root, dirs, files in os.walk(start_directory):
                for filename in files:
                    # Проверяем расширение (включая .SK, .sk, .Sk)
                    if filename.lower().endswith(".txt"):
                        full_path = os.path.join(root, filename)
                        
                        # Добавляем в список для отчета
                        found_files_list.append(full_path)
                        print(f"[НАЙДЕН]: {filename}")
                        
                        # Записываем в итоговый файл
                        outfile.write(f"# ==========================================\n")
                        outfile.write(f"# ФАЙЛ: {filename}\n")
                        outfile.write(f"# ПУТЬ: {full_path}\n")
                        outfile.write(f"# ==========================================\n\n")
                        
                        try:
                            with open(full_path, 'r', encoding='utf-8') as infile:
                                outfile.write(infile.read())
                                outfile.write("\n\n\n")
                        except Exception as e:
                            print(f"!!! ОШИБКА чтения файла {filename}: {e}")
                            outfile.write(f"# [ОШИБКА ЧТЕНИЯ]: {e}\n\n")

    except Exception as e:
        print(f"Критическая ошибка при создании файла отчета: {e}")
        return

    print("-" * 40)
    print(f"ГОТОВО! Собрано файлов: {len(found_files_list)}")
    print(f"Код сохранен в: {output_file}")
    
    # Если файлов 0, возможно скрипт лежит не там
    if len(found_files_list) == 0:
        print("\n[ВНИМАНИЕ] Файлы не найдены!")
        print("Убедитесь, что этот скрипт лежит в папке 'Core' (рядом с папками arenalibs, gamelibs и т.д.)")
    else:
        print("Можешь копировать содержимое collected_sk_code.txt")

if __name__ == "__main__":
    # Точка означает "текущая папка"
    TARGET_DIR = "."
    RESULT_FILE = "collected_sk_code.txt"
    
    collect_all_sk_files(TARGET_DIR, RESULT_FILE)
    
    # Чтобы консоль не закрылась сразу (если запускаешь двойным кликом)
    input("\nНажми Enter, чтобы выйти...")