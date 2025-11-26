#!/usr/bin/env node
/* eslint-disable style/padded-blocks */
/* eslint-disable unused-imports/no-unused-vars */

/**
 * Calculate brightness intensity adjustments for a hex color code
 * 
 * Usage:
 *   node hex-intensity.js <hex> <percent>           # Single percentage
 *   node hex-intensity.js <hex> <start> <end> <step>  # Range of percentages
 * 
 * Examples:
 *   node hex-intensity.js #FF0000 -10                # Single adjustment
 *   node hex-intensity.js #FF0000 -50 50 10          # Range from -50% to +50% in 10% steps
 *   node hex-intensity.js FF0000 -10                 # Hex without # also works
 */

function hexToRgb(hex) {
    // Remove # if present
    hex = hex.replace('#', '')

    if (hex.length !== 6) {
        throw new Error('Hex color must be 6 characters (e.g., #FF0000 or FF0000)')
    }

    // Parse hex values
    const r = Number.parseInt(hex.substring(0, 2), 16)
    const g = Number.parseInt(hex.substring(2, 4), 16)
    const b = Number.parseInt(hex.substring(4, 6), 16)

    return { r, g, b }
}

function rgbToHex(rgb) {
    const r = rgb.r
    const g = rgb.g
    const b = rgb.b

    // Ensure values are within 0-255 range
    const safeR = Math.max(0, Math.min(255, r))
    const safeG = Math.max(0, Math.min(255, g))
    const safeB = Math.max(0, Math.min(255, b))

    const hexR = safeR.toString(16).padStart(2, '0')
    const hexG = safeG.toString(16).padStart(2, '0')
    const hexB = safeB.toString(16).padStart(2, '0')

    return `#${hexR}${hexG}${hexB}`
}

function adjustRgbIntensity(rgb, percentChange) {
    // Adjust RGB values by percentage (-100 to +100)
    // percentChange is a number like -50, -40, ..., 0, ..., +40, +50
    const factor = 1 + (percentChange / 100)

    return {
        r: Math.max(0, Math.min(255, Math.round(rgb.r * factor))),
        g: Math.max(0, Math.min(255, Math.round(rgb.g * factor))),
        b: Math.max(0, Math.min(255, Math.round(rgb.b * factor))),
    }
}

function formatPercent(percent) {
    if (percent === 0) {
        return '  0%'
    }
    return percent > 0 ? `+${percent}%` : `${percent}%`
}

function printSingleAdjustment(hex, percent) {
    const rgb = hexToRgb(hex)
    const adjusted = adjustRgbIntensity(rgb, percent)
    const adjustedHex = rgbToHex(adjusted)

    console.log(`\nOriginal: ${hex} → RGB(${rgb.r}, ${rgb.g}, ${rgb.b})`)
    console.log(`Adjusted: ${adjustedHex} → RGB(${adjusted.r}, ${adjusted.g}, ${adjusted.b})`)
    console.log(`Change:   ${formatPercent(percent)}`)
    console.log(`\nFor lipgloss: Background(lipgloss.Color("${adjustedHex}"))`)
}

function printRangeAdjustments(hex, startPercent, endPercent, step) {
    const rgb = hexToRgb(hex)
    const variations = []

    // Generate variations
    for (let percent = startPercent; percent <= endPercent; percent += step) {
        const adjusted = adjustRgbIntensity(rgb, percent)
        const adjustedHex = rgbToHex(adjusted)
        variations.push({ percent, rgb: adjusted, hex: adjustedHex })
    }

    // Display header
    console.log(`\n┌────────────────────────────────────────────────────────────────────────────┐`)
    console.log(`│  Intensity Variations for ${hex} (RGB: ${rgb.r}, ${rgb.g}, ${rgb.b})`)
    console.log(`└────────────────────────────────────────────────────────────────────────────┘\n`)

    // Display variations in table format
    console.log('Percent    Hex        RGB')
    console.log('─────────────────────────────────────')
    for (const variation of variations) {
        const percentLabel = formatPercent(variation.percent).padEnd(8)
        const hexLabel = variation.hex.padEnd(10)
        const rgbLabel = `(${variation.rgb.r}, ${variation.rgb.g}, ${variation.rgb.b})`
        console.log(`${percentLabel} ${hexLabel} ${rgbLabel}`)
    }

    // Display for easy copy-paste
    console.log(`\nFor lipgloss (Go):`)
    for (const variation of variations) {
        console.log(`  ${formatPercent(variation.percent).trim()}: lipgloss.Color("${variation.hex}")`)
    }
}

// Main execution
const args = process.argv.slice(2)

if (args.length < 2) {
    console.error('Usage:')
    console.error('  node hex-intensity.js <hex> <percent>                    # Single percentage')
    console.error('  node hex-intensity.js <hex> <start> <end> <step>        # Range of percentages')
    console.error('')
    console.error('Examples:')
    console.error('  node hex-intensity.js #FF0000 -10')
    console.error('  node hex-intensity.js #FF0000 -50 50 10')
    console.error('  node hex-intensity.js 2E0000 -5')
    process.exit(1)
}

const hex = args[0]

try {
    if (args.length === 2) {
        // Single percentage
        const percent = Number.parseFloat(args[1])
        printSingleAdjustment(hex, percent)
    }
    else if (args.length === 4) {
        // Range of percentages
        const startPercent = Number.parseFloat(args[1])
        const endPercent = Number.parseFloat(args[2])
        const step = Number.parseFloat(args[3])

        if (step === 0) {
            console.error('Error: Step cannot be 0')
            process.exit(1)
        }

        printRangeAdjustments(hex, startPercent, endPercent, step)
    }
    else {
        console.error('Error: Invalid number of arguments')
        console.error('Use either 2 arguments (hex, percent) or 4 arguments (hex, start, end, step)')
        process.exit(1)
    }
}
catch (error) {
    console.error(`Error: ${error.message}`)
    process.exit(1)
}

