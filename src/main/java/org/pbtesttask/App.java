package org.pbtesttask;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class App {
    private static final Map<Character, List<String>> worldsStartingFrom = new HashMap<>();
    private static List<String> longestResultChain = new LinkedList<>();

    public static void main(String[] args) {
        readFileAndBuildLongestChain("cities.txt");

        System.out.println(String.join(" ", longestResultChain));
    }

    public static void readFileAndBuildLongestChain(String fileName) {
        try (InputStream is = App.class.getClassLoader().getResourceAsStream(fileName)) {
            if (Objects.nonNull(is)) {
                BufferedReader reader =
                        new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
                createMapFromFile(reader);
                worldsStartingFrom
                        .forEach((key, value) -> value.forEach(city ->
                            findLongestChain(new LinkedList<>(List.of(city)), city.charAt(city.length() - 1))
                        ));
            } else {
                throw new RuntimeException("Unable to read file " + fileName);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error processing file " + fileName, e);
        }
    }

    private static void createMapFromFile(BufferedReader reader) throws IOException {
        String line;
        while ((line = reader.readLine()) != null) {
            String city = line.trim().toLowerCase();
            char firstChar = city.charAt(0);
            worldsStartingFrom
                    .computeIfAbsent(firstChar, l -> new ArrayList<>()).add(city);
        }
    }

    private static void findLongestChain(List<String> currentChain, char lastChar) {
        if (currentChain.size() > longestResultChain.size()) {
            longestResultChain = new LinkedList<>(currentChain);
        }
        if (worldsStartingFrom.containsKey(lastChar)) {
            worldsStartingFrom
                    .get(lastChar)
                    .stream()
                    .filter(cityByLetter -> !currentChain.contains(cityByLetter))
                    .forEach(cityByLetter -> {
                        currentChain.add(cityByLetter);
                        findLongestChain(currentChain, cityByLetter.charAt(cityByLetter.length() - 1));
                        currentChain.remove(currentChain.size() - 1);
                    });
        }
    }
}