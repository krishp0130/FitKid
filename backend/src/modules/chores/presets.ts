import type { ChorePreset } from './types.js'

export const CHORE_PRESETS: ChorePreset[] = [
  {
    id: 'make-bed',
    title: 'Make Your Bed',
    description: 'Make your bed every morning',
    rewardDollars: 0.50,
    recurrenceType: 'DAILY'
  },
  {
    id: 'clean-room',
    title: 'Clean Your Room',
    description: 'Keep your room tidy and organized',
    rewardDollars: 2.00,
    recurrenceType: 'WEEKLY',
    suggestedDueDay: 6 // Saturday
  },
  {
    id: 'homework',
    title: 'Complete Homework',
    description: 'Finish all homework assignments',
    rewardDollars: 1.00,
    recurrenceType: 'DAILY'
  },
  {
    id: 'take-out-trash',
    title: 'Take Out Trash',
    description: 'Take trash and recycling to the curb',
    rewardDollars: 1.50,
    recurrenceType: 'WEEKLY',
    suggestedDueDay: 3 // Thursday
  },
  {
    id: 'set-table',
    title: 'Set the Table',
    description: 'Help set the table for dinner',
    rewardDollars: 0.75,
    recurrenceType: 'DAILY'
  },
  {
    id: 'walk-dog',
    title: 'Walk the Dog',
    description: 'Take the dog for a walk',
    rewardDollars: 1.00,
    recurrenceType: 'DAILY'
  },
  {
    id: 'load-dishwasher',
    title: 'Load Dishwasher',
    description: 'Load and start the dishwasher',
    rewardDollars: 1.00,
    recurrenceType: 'DAILY'
  },
  {
    id: 'fold-laundry',
    title: 'Fold Laundry',
    description: 'Fold and put away clean laundry',
    rewardDollars: 2.00,
    recurrenceType: 'WEEKLY'
  },
  {
    id: 'yard-work',
    title: 'Yard Work',
    description: 'Help with yard work and gardening',
    rewardDollars: 3.00,
    recurrenceType: 'WEEKLY',
    suggestedDueDay: 6 // Saturday
  },
  {
    id: 'wash-car',
    title: 'Wash the Car',
    description: 'Wash and clean the family car',
    rewardDollars: 5.00,
    recurrenceType: 'MONTHLY'
  }
]

export function getPresetById(id: string): ChorePreset | undefined {
  return CHORE_PRESETS.find(p => p.id === id)
}



