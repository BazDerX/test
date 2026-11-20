STYLES = {'scandinavian': 'Scandinavian, pale wood, airy functional design', 'warm_minimal': 'warm minimalism, natural tactile materials, uncluttered', 'modern': 'contemporary modern, clean lines', 'classic': 'classic elegant interior, balanced proportions'}
PALETTES = {'beige': 'sand beige and cream', 'sage': 'sage green and neutral linen', 'brown': 'warm brown and natural oak', 'gray': 'light gray and soft white', 'forest': 'forest green with warm neutral accents'}
NEGATIVE = 'floating furniture, distorted architecture, blocked windows, warped doors, unrealistic perspective, text, watermark, clutter'


def build_prompt(request):
    room = 'living room' if request.room_type == 'living' else 'bedroom'
    return (f'Photorealistic interior redesign of the input {room}. {STYLES[request.style]}. '
            f'Color palette: {PALETTES[request.palette]}. Preserve camera perspective, windows and door placement, '
            f'wall and floor geometry as much as possible. Practical grounded furniture. '
            f'Planning budget {request.budget} MNT, not a product price quotation. User instructions: {request.prompt}')
